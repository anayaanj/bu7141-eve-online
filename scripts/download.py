"""Download raw EVE Online data sources into data/raw/ and log each file in sources.csv.

Usage: python scripts/download.py {killmails|characters|market|mer|steam|pricing|news|esi_characters|pearl_abyss|financials|sde|contracts|character_id_boundaries|players_online|fx|steam_players|news_all|wars|sovereignty_campaigns|forums|benchmarks|google_trends|twitch|patch_history|transcript}
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


def fetch(url, retries=5, user_agent=USER_AGENT):
    for attempt in range(retries):
        try:
            return urlopen(Request(url, headers={"User-Agent": user_agent}), timeout=120)
        except HTTPError as e:
            if (e.code not in (420, 429) and e.code < 500) or attempt == retries - 1:
                raise
            reset = e.headers.get("X-ESI-Error-Limit-Reset")  # 420: ESI error limit hit
            time.sleep(int(reset) + 1 if reset else 60 * (attempt + 1))
        except (URLError, OSError):  # includes dropped connections
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


def download(url, path, source, publisher, nature, user_agent=USER_AGENT):
    """Skip files already saved; .part files are renamed only after a complete download."""
    if path.exists():
        return
    path.parent.mkdir(parents=True, exist_ok=True)
    tmp = path.with_suffix(path.suffix + ".part")
    for attempt in range(5):
        try:
            with fetch(url, user_agent=user_agent) as r, open(tmp, "wb") as f:
                expected_size = r.headers.get("Content-Length")
                expected_size = int(expected_size) if expected_size else None
                for chunk in iter(lambda: r.read(1 << 20), b""):
                    f.write(chunk)
            break
        except (URLError, OSError):  # dropped mid-file: start the file again
            if attempt == 4:
                raise
            time.sleep(30 * (attempt + 1))
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


def character_id_boundaries():
    """First character ID created in each month, found by binary search on ESI birthdays.
    Character IDs are allocated in order, so signups in a month = next month's first ID - this month's first ID."""
    out = RAW / "character_id_boundaries"
    out.mkdir(parents=True, exist_ok=True)
    probes_path = out / "probes.jsonl"
    cache = {}
    if probes_path.exists():
        for line in probes_path.open():
            r = json.loads(line)
            cache[r["character_id"]] = r["birthday"]

    def probe(cid):
        for attempt in range(5):
            try:
                return probe_once(cid)
            except (URLError, OSError):  # includes read timeouts mid-response
                if attempt == 4:
                    raise
                time.sleep(30)

    def probe_once(cid):
        if cid not in cache:
            url = f"https://esi.evetech.net/latest/characters/{cid}/?datasource=tranquility"
            try:
                with fetch(url) as r:
                    cache[cid] = json.load(r)["birthday"]
                    headers = r.headers
            except HTTPError as e:
                if e.code not in (404, 410):
                    raise
                cache[cid] = None
                headers = e.headers
            # 404s count against ESI's error limit: pause before it runs out
            if int(headers.get("X-ESI-Error-Limit-Remain") or 100) < 20:
                time.sleep(int(headers.get("X-ESI-Error-Limit-Reset") or 60) + 1)
            with probes_path.open("a") as f:
                f.write(json.dumps({"character_id": cid, "birthday": cache[cid],
                                    "retrieved_at": datetime.now(timezone.utc).isoformat(timespec="seconds")}) + "\n")
        return cache[cid]

    def next_existing(cid):
        """First existing character at or after cid; (None, None) past the newest character."""
        for k in range(30):
            if probe(cid + k):
                return cid + k, cache[cid + k]
        return None, None

    lo, hi = 2121000000, 2124730666  # created before 2024 / a character created 2026-09-23, after END
    rows = []
    month = date(START.year, START.month, 1)
    while month <= date(END.year, END.month, 1).replace(month=END.month % 12 + 1, year=END.year + END.month // 12):
        when = f"{month}T00:00:00Z"
        a, b = lo, hi  # every character below a was created before `when`; every one from b on, on or after
        while b - a > 1:
            mid = (a + b) // 2
            cid, birthday = next_existing(mid)
            if birthday is None or birthday >= when:
                b = mid
            else:
                a = cid
        first_id, first_birthday = next_existing(b)
        rows.append((month.isoformat(), first_id, first_birthday))
        print(month, first_id, first_birthday)
        lo = a
        month = month.replace(month=month.month % 12 + 1, year=month.year + month.month // 12)

    boundaries = out / "boundaries.csv"
    with boundaries.open("w", newline="") as f:
        w = csv.writer(f)
        w.writerow(["month_start", "first_character_id", "first_character_birthday"])
        w.writerows(rows)
    for path in (boundaries, probes_path):
        log_source("Character ID month boundaries (ESI binary search)", "CCP Games (ESI API)",
                   "https://esi.evetech.net/latest/characters/{id}/", path, "real, official public API")


def fx():
    """Daily exchange rates from FRED: KRW per USD and USD per EUR."""
    for series in ["DEXKOUS", "DEXUSEU"]:
        download(f"https://fred.stlouisfed.org/graph/fredgraph.csv?id={series}", RAW / "fx" / f"{series}.csv",
                 f"Exchange rate {series}", "Federal Reserve Bank of St. Louis (FRED)", "real, official statistics",
                 user_agent="python-urllib/3.12")  # FRED drops requests with custom User-Agents


def steam_players():
    """SteamCharts page for EVE Online: monthly average and peak concurrent Steam players."""
    download("https://steamcharts.com/app/8500", RAW / "steam_players" / "steamcharts_8500.html",
             "Steam concurrent players (SteamCharts)", "SteamCharts, from the Steam Web API", "real, third-party tracker")


def news_all():
    """Every CCP news article since 2023 (any category), for the game-event timeline."""
    space, token = "7lhcm73ukv5p", "BSl3tP6oZ_X_T7kAwXhGF_UB30oG4Hvt03lxol2ENB4"
    skip, page = 0, 1
    while True:
        url = (f"https://cdn.contentful.com/spaces/{space}/environments/master/entries?access_token={token}"
               f"&content_type=article&fields.publishingDate[gte]=2023-01-01"
               f"&order=fields.publishingDate&limit=100&skip={skip}")
        path = RAW / "news_all" / f"page_{page:03d}.json"
        download(url, path, "EVE Online news articles (all)", "CCP Games (Contentful CMS)", "real, official announcements")
        skip, page = skip + 100, page + 1
        if skip >= json.loads(path.read_text())["total"]:
            break


def wars():
    """EVE Ref daily wars snapshots (aggressor, defender, declared/started/finished, kills)."""
    for year in YEARS:
        for f in fetch_json(f"https://data.everef.net/wars/history/{year}/index.json")["files"]:
            if START <= date.fromisoformat(f["name"][5:15]) <= END:
                download(f["url"], RAW / "wars" / str(year) / f["name"], "Wars (CCP ESI via EVE Ref)", EVEREF,
                         "real, public game data")


def sovereignty_campaigns():
    """EVE Ref hourly sovereignty campaign snapshots (territory fights)."""
    day = START
    while day <= END:
        try:
            files = fetch_json(f"https://data.everef.net/sovereignty-campaigns/history/{day.year}/{day}/index.json")["files"]
        except HTTPError as e:
            if e.code != 404:
                raise
            files = []
        for f in files:
            download(f["url"], RAW / "sovereignty_campaigns" / str(day.year) / f["name"],
                     "Sovereignty campaigns (CCP ESI via EVE Ref)", EVEREF, "real, public game data")
        day = date.fromordinal(day.toordinal() + 1)


BENCHMARKS = [  # (file name, url, publisher)
    ("lee2011_wowah_dataset.pdf", "http://web.cs.wpi.edu/~claypool/mmsys-dataset/2011/wow/p123.pdf",
     "Lee et al., ACM MMSys 2011"),
    ("khan2020_churn_in_wow.pdf", "https://arxiv.org/pdf/2006.15735", "Khan, arXiv 2020"),
    ("borbora2011_churn_mmorpg_motivation.pdf", "https://dmitriwilliams.com/wp-content/uploads/2020/06/ChurnPrediction.pdf",
     "Borbora et al., 2011 (EverQuest II)"),
    ("lee2019_aion_promotion_events.pdf", "https://arxiv.org/pdf/1909.10851", "Lee et al., arXiv 2019 (AION)"),
    ("wowah_full.parquet", "https://github.com/koaning/wow-avatar-datasets/raw/main/wow-full.parquet",
     "WoWAH dataset (Lee et al. 2011), Parquet copy by V. Warmerdam (calmcode.io)"),
]


def benchmarks():
    """Published MMO churn and retention studies, plus the WoWAH dataset, for sanity checks."""
    for name, url, publisher in BENCHMARKS:
        download(url, RAW / "benchmarks" / name, "MMO churn and retention benchmark", publisher,
                 "real, published research")


def twitch():
    """SullyGnome 365-day Twitch summary for EVE Online (daily viewers, hours watched, streamers).
    The monthly archive pages sit behind a Cloudflare browser check, so only the rolling 365-day page is scripted."""
    download("https://sullygnome.com/game/eve_online/365/summary",
             RAW / "twitch" / f"sullygnome_365d_to_{date.today()}.html", "Twitch viewership, last 365 days (SullyGnome)",
             "SullyGnome, from the Twitch API", "real, third-party tracker")
    # Monthly pages (sullygnome_YYYY-MM.html) are saved by hand in a browser: log any not logged yet
    logged = {row["file"] for row in csv.DictReader(SOURCES_CSV.open())}
    for path in sorted((RAW / "twitch").glob("sullygnome_20??-??.html")):
        if str(path.relative_to(RAW)) not in logged:
            month = path.stem.split("_")[1]
            log_source("Twitch viewership by month (SullyGnome, saved manually)", "SullyGnome, from the Twitch API",
                       f"https://sullygnome.com/game/eve_online/{date.fromisoformat(month + '-01'):%Y%B}".lower(),
                       path, "real, third-party tracker")
            print("logged", path.relative_to(ROOT))


def patch_history():
    """Release timeline: CCP major patch notes (all time), EVE Ref SDE build indexes, EVE University expansion list."""
    out = RAW / "patch_history"
    space, token = "7lhcm73ukv5p", "BSl3tP6oZ_X_T7kAwXhGF_UB30oG4Hvt03lxol2ENB4"
    skip, page = 0, 1
    while True:
        url = (f"https://cdn.contentful.com/spaces/{space}/environments/master/entries?access_token={token}"
               f"&content_type=article&fields.category=patch-notes&order=fields.publishingDate&limit=100&skip={skip}")
        path = out / f"patch_notes_page_{page:02d}.json"
        download(url, path, "EVE Online patch notes (major versions)", "CCP Games (Contentful CMS)",
                 "real, official release notes")
        skip, page = skip + 100, page + 1
        if skip >= json.loads(path.read_text())["total"]:
            break
    for f in fetch_json("https://data.everef.net/ccp/sde/index.json")["directories"]:
        if f["name"].isdigit():  # one index per year; each SDE build ~ one game deployment
            download(f["index_url"], out / f"sde_builds_{f['name']}.json", "SDE build history (index)",
                     "CCP Games (mirrored by EVE Ref)", "real, official release metadata")
    download("https://wiki.eveuniversity.org/Expansions", out / "eveuni_expansions.html",
             "EVE Online expansions list", "EVE University wiki (CC BY-SA)", "real, community-maintained reference")


def transcript():
    """Transcript of 'EVE Online | Down the Rabbit Hole' (Fredrik Knudsen) for lore events.
    Needs: pip install youtube-transcript-api. Kept out of git (data/raw is ignored): cite, don't redistribute."""
    from youtube_transcript_api import YouTubeTranscriptApi
    video_id = "BCSeISYcoyI"
    path = RAW / "qualitative" / f"down_the_rabbit_hole_{video_id}.json"
    if path.exists():
        return
    path.parent.mkdir(parents=True, exist_ok=True)
    snippets = [{"start": s.start, "duration": s.duration, "text": s.text}
                for s in YouTubeTranscriptApi().fetch(video_id)]
    path.write_text(json.dumps(snippets, ensure_ascii=False, indent=0))
    log_source("EVE Online | Down the Rabbit Hole (video transcript)", "Fredrik Knudsen (YouTube)",
               f"https://www.youtube.com/watch?v={video_id}", path, "real, secondary source (player documentary)")
    print("saved", path.relative_to(ROOT), len(snippets), "lines")


def google_trends():
    """Log manually exported Google Trends CSVs in data/raw/google_trends/ (Google blocks scripted downloads)."""
    logged = {row["file"] for row in csv.DictReader(SOURCES_CSV.open())}
    for path in sorted((RAW / "google_trends").glob("*.csv")):
        if str(path.relative_to(RAW)) not in logged:
            log_source("Google Trends interest over time (manual export)", "Google",
                       "https://trends.google.com/trends/explore", path, "real, normalised index (0-100)")
            print("logged", path.relative_to(ROOT))


# Only threads whose title is on topic: searches also match off-topic threads (e.g. forum games) through one post
FORUM_TITLE_FILTER = re.compile(r"omega|plex|price|pric|subscri|pearl|fenris|new player|newbie|new bro|unsub|quit|leav"
                                r"|monetiz|alpha", re.I)
FORUM_QUERIES = ["omega price", "plex price", "subscription", "pearl abyss", "fenris", "new player", "unsubscribed"]


def forums():
    """EVE Online official forum topics (Discourse JSON) matching FORUM_QUERIES, created in the window."""
    base = "https://forums.eveonline.com"
    out = RAW / "forums"
    topic_ids = set()
    for query in FORUM_QUERIES:
        page = 1
        while True:
            q = quote(f"{query} after:{START} before:{END}")
            path = out / "search" / f"{query.replace(' ', '_')}_page_{page:02d}.json"
            try:
                download(f"{base}/search.json?q={q}&page={page}", path, "EVE Online forums search",
                         "CCP Games (forums.eveonline.com)", "real, public user posts")
            except HTTPError as e:
                if e.code != 400:  # Discourse returns 400 past its last search page (10)
                    raise
                break
            data = json.loads(path.read_text())
            topic_ids |= {t["id"] for t in data.get("topics", []) if FORUM_TITLE_FILTER.search(t["title"])}
            if not data.get("grouped_search_result", {}).get("more_full_page_results"):
                break
            page += 1
            time.sleep(2)
    for tid in sorted(topic_ids):
        page = 1
        while True:  # 20 posts per page
            path = out / "topics" / f"{tid}_page_{page:03d}.json"
            download(f"{base}/t/{tid}.json?page={page}", path, "EVE Online forums topic",
                     "CCP Games (forums.eveonline.com)", "real, public user posts")
            topic = json.loads(path.read_text())
            time.sleep(2)
            if page * 20 >= topic.get("posts_count", 0):
                break
            page += 1


def players_online():
    """Concurrent players on Tranquility from EVE-Offline, one request per month (~1.5 h resolution)."""
    month = date(START.year, START.month, 1)
    while month <= END:
        nxt = month.replace(month=month.month % 12 + 1, year=month.year + month.month // 12)
        start_ms = int(datetime(month.year, month.month, 1, tzinfo=timezone.utc).timestamp() * 1000)
        end_ms = int(datetime(nxt.year, nxt.month, 1, tzinfo=timezone.utc).timestamp() * 1000)
        download(f"https://eve-offline.net/data/?server=tranquility&start={start_ms}&end={end_ms}",
                 RAW / "players_online" / f"tranquility_{month:%Y-%m}.jsonp",
                 "Concurrent players online (EVE-Offline)", "EVE-Offline (eve-offline.net), polling CCP server status",
                 "real, third-party tracker")
        time.sleep(2)
        month = nxt


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
     "contracts": contracts, "character_id_boundaries": character_id_boundaries,
     "players_online": players_online, "fx": fx, "steam_players": steam_players, "news_all": news_all,
     "wars": wars, "sovereignty_campaigns": sovereignty_campaigns, "forums": forums,
     "benchmarks": benchmarks, "google_trends": google_trends,
     "twitch": twitch, "patch_history": patch_history, "transcript": transcript}[sys.argv[1]]()
