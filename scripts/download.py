"""Download raw EVE Online data sources into data/raw/ and log each file in sources.csv.

Usage: python scripts/download.py {killmails|characters|market|mer|steam|pricing|news|esi_characters|pearl_abyss|financials|sde|contracts}
"""
import csv
import hashlib
import json
import os
import re
import sys
import tarfile
import time
from concurrent.futures import ThreadPoolExecutor
from datetime import date, datetime, timezone
from html import unescape
from multiprocessing import Pool
from pathlib import Path
from urllib.error import HTTPError, URLError
from urllib.parse import quote
from urllib.request import Request, urlopen

ROOT = Path(__file__).resolve().parent.parent
RAW = ROOT / "data" / "raw"
SOURCES_CSV = RAW / "sources.csv"
# CCP asks ESI users to include a contact address: export CONTACT_EMAIL=you@example.com
USER_AGENT = f"BU7141-TCD-student-project ({os.environ.get('CONTACT_EMAIL', 'no contact set')})"
START, END = date(2024, 1, 1), date(2026, 8, 31)
YEARS = range(START.year, END.year + 1)

EVEREF = "EVE Ref (data.everef.net)"


def fetch(url, retries=5):
    for attempt in range(retries):
        try:
            return urlopen(Request(url, headers={"User-Agent": USER_AGENT}), timeout=120)
        except HTTPError as e:
            if e.code != 429 or attempt == retries - 1:
                raise
            time.sleep(60 * (attempt + 1))
        except URLError:
            if attempt == retries - 1:
                raise
            time.sleep(30 * (attempt + 1))


def fetch_json(url):
    with fetch(url) as r:
        return json.load(r)


def log_source(source, publisher, url, path, nature):
    new = not SOURCES_CSV.exists()
    sha = hashlib.sha256()
    with open(path, "rb") as f:
        for chunk in iter(lambda: f.read(1 << 20), b""):
            sha.update(chunk)
    with open(SOURCES_CSV, "a", newline="") as f:
        w = csv.writer(f)
        if new:
            w.writerow(["source", "publisher", "url", "file", "retrieved_at", "bytes", "sha256", "data_nature"])
        w.writerow([source, publisher, url, path.relative_to(RAW), datetime.now(timezone.utc).isoformat(timespec="seconds"),
                    path.stat().st_size, sha.hexdigest(), nature])


def download(url, path, source, publisher, nature):
    """Skip files already saved; .part files are renamed only after a complete download."""
    if path.exists():
        return
    path.parent.mkdir(parents=True, exist_ok=True)
    tmp = path.with_suffix(path.suffix + ".part")
    with fetch(url) as r, open(tmp, "wb") as f:
        expected_size = r.headers.get("Content-Length")
        expected_size = int(expected_size) if expected_size else None
        for chunk in iter(lambda: r.read(1 << 20), b""):
            f.write(chunk)
    if expected_size is not None and tmp.stat().st_size != expected_size:
        raise RuntimeError(f"Size mismatch for {url}: {tmp.stat().st_size} != {expected_size}")
    tmp.rename(path)
    log_source(source, publisher, url, path, nature)
    print("saved", path.relative_to(ROOT))


def everef_daily(dataset, source, nature):
    """Download daily EVE Ref files within START..END, using each year's index.json."""
    for year in YEARS:
        index = fetch_json(f"https://data.everef.net/{dataset}/{year}/index.json")
        for f in index["files"]:
            day = date.fromisoformat(f["file_time"][:10])
            if START <= day <= END:
                path = RAW / dataset.replace("-", "_") / str(year) / f["name"]
                download(f["url"], path, source, EVEREF, nature)


def killmails():
    everef_daily("killmails", "Killmails (zKillboard via EVE Ref)", "real, public game events")


def market():
    everef_daily("market-history", "Market history (CCP ESI via EVE Ref)", "real, aggregated daily per region/type")


def characters():
    name = "eve-kill-com-karbowiak-2026-05-10.tar.bz2"
    url = f"https://data.everef.net/characters-corporations-alliances/backfills/{name}"
    download(url, RAW / "characters" / name, "Characters/corporations/alliances (eve-kill.com via EVE Ref)", EVEREF,
             "real, public character records")


def mer():
    for year in YEARS:
        for f in fetch_json(f"https://data.everef.net/ccp/mer/{year}/index.json")["files"]:
            download(f["url"], RAW / "mer" / f["name"], "Monthly Economic Report", "CCP Games (mirrored by EVE Ref)",
                     "real, official aggregates")


def steam():
    out = RAW / "steam_reviews"
    out.mkdir(parents=True, exist_ok=True)
    pages = sorted(out.glob("reviews_page_*.json"))
    cursor, page = (json.loads(pages[-1].read_text())["cursor"], len(pages) + 1) if pages else ("*", 1)
    while True:
        path = out / f"reviews_page_{page:04d}.json"
        url = ("https://store.steampowered.com/appreviews/8500?json=1&filter=recent&language=all"
               f"&review_type=all&purchase_type=all&num_per_page=100&cursor={quote(cursor)}")
        with fetch(url) as r:
            body = r.read()
        data = json.loads(body)
        if not data.get("reviews"):
            break
        path.write_bytes(body)
        log_source("Steam user reviews (app 8500)", "Valve / Steam", url, path, "real, public user reviews")
        print("saved", path.relative_to(ROOT), len(data["reviews"]))
        if data["cursor"] == cursor:
            break
        cursor, page = data["cursor"], page + 1
        time.sleep(1)


def pricing():
    """First Wayback snapshot per month of the Omega and store pages."""
    for page in ["www.eveonline.com/omega", "store.eveonline.com/"]:
        cdx = fetch_json(f"https://web.archive.org/cdx/search/cdx?url={page}&from={START.year}&to={END.year}"
                         "&filter=statuscode:200&collapse=timestamp:6&output=json")
        for _, ts, original, *_ in cdx[1:]:
            slug = page.strip("/").replace("/", "_")
            download(f"https://web.archive.org/web/{ts}id_/{original}", RAW / "pricing" / f"{slug}_{ts}.html",
                     "Omega / store pricing page (Wayback Machine snapshot)", "CCP Games (archived by Internet Archive)",
                     "real, archived web page")
            time.sleep(5)


def news():
    """CCP news articles mentioning Omega or PLEX, from the Contentful API behind eveonline.com.
    The read-only token is the public one embedded in eveonline.com's JavaScript."""
    space, token = "7lhcm73ukv5p", "BSl3tP6oZ_X_T7kAwXhGF_UB30oG4Hvt03lxol2ENB4"
    for term in ["omega", "plex"]:
        skip, page = 0, 1
        while True:
            url = (f"https://cdn.contentful.com/spaces/{space}/environments/master/entries?access_token={token}"
                   f"&content_type=article&query={term}&fields.publishingDate[gte]=2023-01-01"
                   f"&order=fields.publishingDate&limit=100&skip={skip}")
            path = RAW / "news" / f"{term}_page_{page:03d}.json"
            download(url, path, f"EVE Online news articles mentioning '{term}'", "CCP Games (Contentful CMS)",
                     "real, official announcements")
            data = json.loads(path.read_text())
            skip, page = skip + 100, page + 1
            if skip >= data["total"]:
                break


def killmail_character_ids(path):
    ids = set()
    with tarfile.open(path, "r:bz2") as tar:
        for member in tar:
            if member.isfile() and member.name.endswith(".json"):
                km = json.load(tar.extractfile(member))
                ids.add(km["victim"].get("character_id"))
                ids.update(a.get("character_id") for a in km["attackers"])
    ids.discard(None)
    return ids


def esi_characters():
    """Fetch ESI character records for killmail characters with no real birthday in the character dump."""
    out = RAW / "esi_characters"
    out.mkdir(parents=True, exist_ok=True)
    ids_file = out / "character_ids_to_fetch.txt"
    if not ids_file.exists():
        with Pool() as pool:
            ids = set().union(*pool.imap_unordered(killmail_character_ids, sorted((RAW / "killmails").rglob("*.tar.bz2"))))
        print("killmail characters", len(ids))
        known = set()
        dump = RAW / "characters" / "eve-kill-com-karbowiak-2026-05-10.tar.bz2"
        with tarfile.open(dump, "r:bz2") as tar:
            f = tar.extractfile("eve-kill-com-karbowiak-2026-05-10/characters.json")
            for line in f:
                line = line.strip().rstrip(b",").lstrip(b"[").rstrip(b"]")
                if not line:
                    continue
                c = json.loads(line)
                if c["character_id"] in ids and (c["birthday"] or "") >= "2003":
                    known.add(c["character_id"])
        ids_file.write_text("\n".join(map(str, sorted(ids - known))))
        print("to fetch", len(ids - known))

    results = out / "characters.jsonl"
    done = set()
    if results.exists():
        done = {json.loads(line)["character_id"] for line in results.open()}
    todo = [int(i) for i in ids_file.read_text().split() if int(i) not in done]
    print("remaining", len(todo))

    def get(cid):
        url = f"https://esi.evetech.net/latest/characters/{cid}/?datasource=tranquility"
        for attempt in range(5):
            try:
                with fetch(url) as r:
                    return {"character_id": cid, "status": r.status, "body": json.load(r)}
            except HTTPError as e:
                if e.code in (404, 410):
                    return {"character_id": cid, "status": e.code, "body": None}
                time.sleep(int(e.headers.get("Retry-After") or 30))
            except (URLError, OSError):
                time.sleep(30)
        return None  # not written, so the next run retries it

    with ThreadPoolExecutor(8) as ex, results.open("a") as f:
        for n, rec in enumerate(ex.map(get, todo), 1):
            if rec:
                rec["retrieved_at"] = datetime.now(timezone.utc).isoformat(timespec="seconds")
                f.write(json.dumps(rec) + "\n")
            if n % 10000 == 0:
                f.flush()
                print("fetched", n)
    log_source("ESI character records", "CCP Games (ESI API)", "https://esi.evetech.net/latest/characters/{id}/",
               results, "real, official public API")


def contracts():
    """First public-contracts snapshot of each day. Each snapshot lists every open contract, with issuer and date."""
    day = START
    while day <= END:
        try:
            files = fetch_json(f"https://data.everef.net/public-contracts/history/{day.year}/{day}/index.json")["files"]
        except HTTPError as e:
            if e.code != 404:
                raise
            files = []
        if files:
            f = min(files, key=lambda f: f["name"])
            download(f["url"], RAW / "public_contracts" / str(day.year) / f["name"],
                     "Public contracts (CCP ESI via EVE Ref)", EVEREF, "real, public contract snapshots")
        else:
            print("no snapshot", day)
        day = date.fromordinal(day.toordinal() + 1)


def sde():
    """CCP's static game data (item types, groups, categories, map), JSONL edition."""
    name = "eve-online-static-data-latest-jsonl.zip"
    download(f"https://data.everef.net/ccp/sde/{name}", RAW / "sde" / name, "EVE Online static data export (SDE)",
             "CCP Games (mirrored by EVE Ref)", "real, official reference data")


def pearl_abyss():
    """Pearl Abyss IR: earnings releases (from 1Q23), IR letters (from 2024) and the Financial Info page."""
    base = "https://www.pearlabyss.com"
    out = RAW / "financials" / "pearl_abyss"
    source, publisher, nature = "Pearl Abyss investor relations", "Pearl Abyss Corp.", "real, official filings"
    download(f"{base}/en-US/IR/Financial", out / "financial_info.html", source, publisher, nature)
    for board, since in [("Performance", date(2023, 1, 1)), ("Letter", START)]:
        page, done = 1, False
        while not done:
            with fetch(f"{base}/en-US/IR/Data/{board}?_pageNo={page}") as r:
                html = r.read().decode("utf-8")
            rows = re.findall(r'_boardNo=(\d+)" target="_self">[^<]+</a>\s*</td>\s*<td class="roboto">([^<]+)<', html)
            done = not rows
            for board_no, posted in rows:
                if datetime.strptime(posted.strip(), "%b %d, %Y").date() < since:
                    done = True
                    break
                with fetch(f"{base}/en-US/Board/Detail?_boardNo={board_no}") as r:
                    detail = r.read().decode("utf-8")
                for name, link in re.findall(r'<div class="file">([^<]+)</div>\s*<div class="download"><a href="([^"]+)"', detail):
                    download(base + unescape(link), out / board.lower() / f"{board_no}_{name.strip()}", source, publisher, nature)
                time.sleep(1)
            page += 1


def financials():
    """Log manually downloaded files in data/raw/financials/ that aren't in sources.csv yet."""
    logged = {row["file"] for row in csv.DictReader(SOURCES_CSV.open())}
    sources = {
        "pearl_abyss": ("Pearl Abyss quarterly earnings", "Pearl Abyss Corp.",
                        "https://www.pearlabyss.com/en-US/Company/IR/Earnings"),
        "ccp": ("CCP ehf. annual accounts (kennitala 450697-3469)", "Skatturinn (Iceland Revenue and Customs)",
                "https://www.skatturinn.is/fyrirtaekjaskra/leit/kennitala/4506973469"),
    }
    for folder, (source, publisher, url) in sources.items():
        for path in sorted(p for p in (RAW / "financials" / folder).rglob("*") if p.is_file()):
            if str(path.relative_to(RAW)) not in logged:
                log_source(source, publisher, url, path, "real, official filings")
                print("logged", path.relative_to(ROOT))


if __name__ == "__main__":
    {"killmails": killmails, "characters": characters, "market": market, "mer": mer, "steam": steam,
     "pricing": pricing, "news": news, "esi_characters": esi_characters,
     "financials": financials, "pearl_abyss": pearl_abyss, "sde": sde,
     "contracts": contracts}[sys.argv[1]]()
