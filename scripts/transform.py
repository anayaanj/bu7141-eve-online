"""Transform data/raw into one clean CSV per ERD table (data/clean/<table>.csv.gz), ready for scripts/load.sh.

Phase 1 (core): dimensions, wars, killmails, placeholders, contracts, characters, activity.
Phase 2: sources, market, players_online, sov_campaigns, steam, forums, fx, economy, interest, game_events.
Phase 3: curated (financial figures, plan prices, benchmarks from data/reference/).
Usage: python3 scripts/transform.py <step>|all
Steps run in that order; later steps read the work files of earlier ones (data/clean/_work/).
"""
import bz2
import csv
import gzip
import hashlib
import io
import json
import pickle
import sys
import tarfile
import zipfile
from datetime import date, datetime, timedelta
from multiprocessing import Pool
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
RAW = ROOT / "data" / "raw"
CLEAN = ROOT / "data" / "clean"
WORK = CLEAN / "_work"
START, END = date(2024, 1, 1), date(2026, 8, 31)
SALE_DATE = date(2026, 5, 6)  # sale of CCP completed (Pearl Abyss 2Q26 letter)
SDE = RAW / "sde" / "eve-online-static-data-latest-jsonl.zip"
MER = RAW / "mer" / "EVEOnline_MER_202608.zip"  # each MER holds the full history; use the latest
CHAR_DUMP = RAW / "characters" / "eve-kill-com-karbowiak-2026-05-10.tar.bz2"
DOOMHEIM = 1000001
UNKNOWN = -1  # placeholder id (0 is a real SDE id) for referenced rows missing from the sources


def out(table, header):
    """Open data/clean/<table>.csv.gz for writing and write the header."""
    CLEAN.mkdir(parents=True, exist_ok=True)
    f = gzip.open(CLEAN / f"{table}.csv.gz", "wt", newline="", encoding="utf-8")
    w = csv.writer(f)
    w.writerow(header)
    return f, w


def save(name, obj):
    WORK.mkdir(parents=True, exist_ok=True)
    with open(WORK / f"{name}.pkl", "wb") as f:
        pickle.dump(obj, f, protocol=pickle.HIGHEST_PROTOCOL)


def load(name):
    with open(WORK / f"{name}.pkl", "rb") as f:
        return pickle.load(f)


def sde_rows(name):
    with zipfile.ZipFile(SDE) as z, z.open(f"{name}.jsonl") as f:
        for line in f:
            yield json.loads(line)


def en(name):
    return name.get("en") if isinstance(name, dict) else name


def month_of(d):
    return d[:7] + "-01"


# ───────────────────────── Dimensions ─────────────────────────

REQUIRED_SKILLS = [(182, 277), (183, 278), (184, 279), (1285, 1286), (1289, 1287), (1290, 1288)]  # (skill, level)


def dimensions():
    # calendar_date: 1997 (CCP founded, earliest lore event) to end of 2026
    f, w = out("calendar_date", ["date", "month", "quarter", "year", "after_sale"])
    d = date(1997, 1, 1)
    while d <= date(2026, 12, 31):
        w.writerow([d, d.replace(day=1), f"{d.year}Q{(d.month - 1) // 3 + 1}", d.year, d >= SALE_DATE])
        d += timedelta(days=1)
    f.close()

    f, w = out("region", ["region_id", "region_name"])
    for r in sde_rows("mapRegions"):
        w.writerow([r["_key"], en(r["name"])])
    f.close()

    f, w = out("constellation", ["constellation_id", "constellation_name", "region_id"])
    for r in sde_rows("mapConstellations"):
        w.writerow([r["_key"], en(r["name"]), r["regionID"]])
    f.close()

    # security band: MER label where listed, else the security-status rule
    with zipfile.ZipFile(MER) as z:
        mer = {int(r["solarsystem_id"]): r["solarsystem_metagroup"]
               for r in csv.DictReader(io.TextIOWrapper(z.open("data/static_solarsystems.csv"), encoding="utf-8"))}
    systems = set()
    starter = {r["solarSystemID"] for r in sde_rows("schoolMap")}
    f, w = out("solar_system", ["solar_system_id", "solar_system_name", "constellation_id", "security_status", "security_band",
                                "map_x", "map_y", "is_starter_system"])
    for r in sde_rows("mapSolarSystems"):
        sec = r.get("securityStatus")
        band = mer.get(r["_key"]) or (
            "Wormhole" if 11000000 <= r["regionID"] < 12000000 else
            "High Sec" if sec is not None and sec >= 0.45 else
            "Low Sec" if sec is not None and sec > 0 else "Null Sec")
        pos = r.get("position2D") if r["regionID"] < 11000000 else None  # wormholes and abyssal space are off the map
        w.writerow([r["_key"], en(r["name"]), r["constellationID"], sec, band,
                    pos and pos["x"], pos and pos["y"], r["_key"] in starter])
        systems.add(r["_key"])
    f.close()

    # stargate_link: each connection once (lower system ID first)
    f, w = out("stargate_link", ["from_solar_system_id", "to_solar_system_id"])
    for a, b in sorted({tuple(sorted((r["solarSystemID"], r["destination"]["solarSystemID"]))) for r in sde_rows("mapStargates")}):
        w.writerow([a, b])
    f.close()

    f, w = out("item_category", ["category_id", "category_name"])
    w.writerow([UNKNOWN, "Unknown"])
    for r in sde_rows("categories"):
        w.writerow([r["_key"], en(r["name"])])
    f.close()

    f, w = out("item_group", ["group_id", "group_name", "category_id"])
    w.writerow([UNKNOWN, "Unknown", UNKNOWN])
    group_category = {}
    for r in sde_rows("groups"):
        w.writerow([r["_key"], en(r["name"]), r["categoryID"]])
        group_category[r["_key"]] = r["categoryID"]
    f.close()

    # alpha_can_fly: every required skill (and its prerequisites, recursively) within the Alpha limits
    alpha = {s["typeID"]: s["level"] for s in next(sde_rows("cloneGrades"))["skills"]}  # all 4 grades are identical
    requires = {}
    for r in sde_rows("typeDogma"):
        a = {x["attributeID"]: x["value"] for x in r.get("dogmaAttributes", [])}
        reqs = [(int(a[s]), int(a.get(l, 1))) for s, l in REQUIRED_SKILLS if a.get(s)]
        if reqs:
            requires[r["_key"]] = reqs
    memo = {}

    def trainable(skill, level):
        if level > alpha.get(skill, 0):
            return False
        if skill not in memo:
            memo[skill] = True  # guards against cycles
            memo[skill] = all(trainable(s, l) for s, l in requires.get(skill, []))
        return memo[skill]

    with zipfile.ZipFile(MER) as z:
        values = {int(r["type_id"]): r["mean_isk_value"]
                  for r in csv.DictReader(io.TextIOWrapper(z.open("data/static_type_values.csv"), encoding="utf-8"))}
    omega_ships, types = set(), set()
    f, w = out("item_type", ["type_id", "type_name", "group_id", "mean_isk_value", "alpha_can_fly"])
    for r in sde_rows("types"):
        is_ship = group_category.get(r["groupID"]) == 6
        can_fly = all(trainable(s, l) for s, l in requires.get(r["_key"], [])) if is_ship else None
        if can_fly is False:
            omega_ships.add(r["_key"])
        w.writerow([r["_key"], en(r["name"]), r["groupID"], values.get(r["_key"]), can_fly])
        types.add(r["_key"])
    f.close()
    save("dimensions", {"omega_ships": omega_ships, "types": types, "systems": systems})
    print(f"dimensions: {len(types):,} types ({len(omega_ships):,} Omega-only ships), {len(systems):,} systems")


# ───────────────────────── Wars ─────────────────────────

def wars():
    latest = {}  # war_id -> war JSON from the latest daily snapshot containing it
    for path in sorted((RAW / "wars").rglob("*.tar.bz2")):
        with tarfile.open(path, "r:bz2") as tar:
            for m in tar:
                if m.isfile() and m.name.endswith(".json"):
                    war = json.load(tar.extractfile(m))
                    if "aggressor" in war:  # the archives also hold each war's killmails: skip those
                        latest[war["war_id"]] = war
    f, w = out("war", ["war_id", "aggressor_corporation_id", "aggressor_alliance_id", "defender_corporation_id",
                       "defender_alliance_id", "declared", "started", "finished", "mutual", "open_for_allies",
                       "aggressor_ships_killed", "defender_ships_killed"])
    for war in latest.values():
        a, d = war["aggressor"], war["defender"]
        w.writerow([war["war_id"], a.get("corporation_id"), a.get("alliance_id"), d.get("corporation_id"),
                    d.get("alliance_id"), war.get("declared"), war.get("started"), war.get("finished"),
                    war.get("mutual"), war.get("open_for_allies"), a.get("ships_killed"), d.get("ships_killed")])
    f.close()
    corps = {x for war in latest.values() for x in (war["aggressor"].get("corporation_id"), war["defender"].get("corporation_id")) if x}
    alliances = {x for war in latest.values() for x in (war["aggressor"].get("alliance_id"), war["defender"].get("alliance_id")) if x}
    save("wars", {"wars": set(latest), "corps": corps, "alliances": alliances})
    print(f"wars: {len(latest):,}")


# ───────────────────────── Killmails ─────────────────────────

BATTLE_MIN_PILOTS, WAR_MIN_PILOTS = 50, 100


def killmail_day(args):
    """One daily archive: write its killmail and participant rows, return per-character monthly aggregates."""
    path, omega_ships = args
    day = path.name[10:20]
    parts = WORK / "killmail_parts"
    km_f = gzip.open(parts / f"killmail_{day}.csv.gz", "wt", newline="")
    kp_f = gzip.open(parts / f"killmail_participant_{day}.csv.gz", "wt", newline="")
    km_w, kp_w = csv.writer(km_f), csv.writer(kp_f)
    activity = {}  # character -> [kills, losses, day_bits, flew_omega, last_time, last_corp]
    first_omega = {}
    buckets = {}  # (system, hour) -> [pilots, killmail ids]
    types, corps, alliances, systems, war_ids = set(), set(), set(), set(), set()
    day_bit = 1 << (int(day[8:10]) - 1)
    with tarfile.open(path, "r:bz2") as tar:
        for member in tar:
            if not (member.isfile() and member.name.endswith(".json")):
                continue
            km = json.load(tar.extractfile(member))
            t = km["killmail_time"]
            if t[:10] != day:  # some archives also hold the previous day's killmails (duplicates): keep each once
                continue
            system = km["solar_system_id"]
            systems.add(system)
            if km.get("war_id"):
                war_ids.add(km["war_id"])
            km_w.writerow([km["killmail_id"], t, t[:10], system, km.get("war_id"), "", len(km["attackers"])])
            people = [(0, "victim", km["victim"])] + [(i, "attacker", a) for i, a in enumerate(km["attackers"], 1)]
            bucket = buckets.setdefault((system, t[:13]), [set(), []])
            bucket[1].append(km["killmail_id"])
            for no, role, p in people:
                c, ship = p.get("character_id"), p.get("ship_type_id")
                kp_w.writerow([km["killmail_id"], no, role, c, p.get("corporation_id"), p.get("alliance_id"), ship,
                               p.get("weapon_type_id"), p.get("damage_taken" if no == 0 else "damage_done"),
                               p.get("final_blow", False)])
                for x, s in ((ship, types), (p.get("weapon_type_id"), types),
                             (p.get("corporation_id"), corps), (p.get("alliance_id"), alliances)):
                    if x:
                        s.add(x)
                if not c:
                    continue
                bucket[0].add(c)
                a = activity.setdefault(c, [0, 0, 0, False, "", None])
                a[0 if no else 1] += 1
                a[2] |= day_bit
                if ship in omega_ships:
                    a[3] = True
                    first_omega.setdefault(c, day)
                if t >= a[4]:
                    a[4], a[5] = t, p.get("corporation_id")
    km_f.close()
    kp_f.close()
    big = {k: (v[0], v[1]) for k, v in buckets.items() if len(v[0]) >= BATTLE_MIN_PILOTS}
    return day, activity, first_omega, big, types, corps, alliances, systems, war_ids


def killmails():
    omega_ships = load("dimensions")["omega_ships"]
    (WORK / "killmail_parts").mkdir(parents=True, exist_ok=True)
    files = [p for p in sorted((RAW / "killmails").rglob("*.tar.bz2")) if START <= date.fromisoformat(p.name[10:20]) <= END]
    km_activity, first_omega, buckets = {}, {}, {}
    refs = {k: set() for k in ("types", "corps", "alliances", "systems", "wars")}
    with Pool() as pool:
        for n, (day, activity, fo, big, types, corps, alliances, systems, war_ids) in enumerate(
                pool.imap_unordered(killmail_day, [(p, omega_ships) for p in files]), 1):
            month = day[:7]
            for c, a in activity.items():
                m = km_activity.setdefault(c, {}).setdefault(month, [0, 0, 0, False, "", None])
                m[0] += a[0]
                m[1] += a[1]
                m[2] |= a[2]
                m[3] = m[3] or a[3]
                if a[4] >= m[4]:
                    m[4], m[5] = a[4], a[5]
            for c, d in fo.items():
                if c not in first_omega or d < first_omega[c]:
                    first_omega[c] = d
            buckets.update(big)
            for k, s in zip(refs, (types, corps, alliances, systems, war_ids)):
                refs[k] |= s
            if n % 100 == 0:
                print(f"killmails: {n}/{len(files)} days", flush=True)

    # battles: qualifying (system, hour) buckets, consecutive hours in the same system merged
    battles, killmail_battle = [], []
    for (system, hour) in sorted(buckets, key=lambda k: (k[0], k[1])):
        pilots, ids = buckets[(system, hour)]
        start = datetime.fromisoformat(hour + ":00:00")
        prev = battles[-1] if battles else None
        if prev and prev["system"] == system and start - prev["last_hour"] <= timedelta(hours=1):
            prev["pilots"] |= pilots
            prev["ids"] += ids
            prev["last_hour"] = start
        else:
            battles.append({"system": system, "first_hour": start, "last_hour": start, "pilots": set(pilots), "ids": list(ids)})
    f, w = out("battle", ["battle_id", "solar_system_id", "start_time", "end_time", "battle_date", "killmails", "pilots", "battle_class"])
    for i, b in enumerate(battles, 1):
        end = b["last_hour"] + timedelta(hours=1)
        w.writerow([i, b["system"], f"{b['first_hour']:%Y-%m-%dT%H:%M:%SZ}", f"{end:%Y-%m-%dT%H:%M:%SZ}",
                    b["first_hour"].date(), len(b["ids"]), len(b["pilots"]),
                    "war" if len(b["pilots"]) >= WAR_MIN_PILOTS else "skirmish"])
        killmail_battle += [(k, i) for k in b["ids"]]
    f.close()
    f, w = out("killmail_battle", ["killmail_id", "battle_id"])
    w.writerows(killmail_battle)
    f.close()
    save("killmails", {"activity": km_activity, "first_omega": first_omega, **refs})
    placeholders()
    print(f"killmails: {len(km_activity):,} characters, {len(battles):,} battles "
          f"({sum(len(b['pilots']) >= WAR_MIN_PILOTS for b in battles):,} wars)")


def existing_ids(table):
    with gzip.open(CLEAN / f"{table}.csv.gz", "rt") as f:
        return {int(r[0]) for r in list(csv.reader(f))[1:]}


def placeholders():
    """Referenced item types and wars missing from the SDE / war snapshots get placeholder rows, so every
    foreign key holds. Idempotent: only adds ids not already in the file."""
    refs = load("killmails")
    missing_types = refs["types"] - existing_ids("item_type")
    missing_wars = refs["wars"] - existing_ids("war")
    with gzip.open(CLEAN / "item_type.csv.gz", "at", newline="") as f:
        csv.writer(f).writerows([t, f"Unknown type {t}", UNKNOWN, None, None] for t in sorted(missing_types))
    with gzip.open(CLEAN / "war.csv.gz", "at", newline="") as f:
        csv.writer(f).writerows([w] + [None] * 11 for w in sorted(missing_wars))
    if refs["systems"] - load("dimensions")["systems"]:
        print("WARNING: solar systems missing from the SDE:", sorted(refs["systems"] - load("dimensions")["systems"])[:10])
    print(f"placeholders: {len(missing_types)} item types, {len(missing_wars)} wars")


# ───────────────────────── Contracts ─────────────────────────

# Items bought with real money from CCP's store: PLEX, Skill Extractor, Large/Small Skill Injector,
# Multiple Pilot Training Certificate, Daily Alpha Injector (type ids from the SDE)
STORE_TYPES = {44992, 40519, 40520, 45635, 34133, 46375}
PLEX = 44992
CONTRACT_FIELDS = ["contract_id", "issuer_id", "issuer_corporation_id", "type", "date_issued", "date_expired",
                   "price", "reward", "collateral", "volume", "region_id", "system_id"]


def contract_snapshot(path):
    day = path.name[17:27]  # public-contracts-YYYY-MM-DD_...
    rows, items = {}, {}
    with tarfile.open(path, "r:bz2") as tar:
        for r in csv.DictReader(io.TextIOWrapper(tar.extractfile("contracts.csv"), encoding="utf-8")):
            if START.isoformat() <= r["date_issued"][:10] <= END.isoformat():
                rows[r["contract_id"]] = [r[k] for k in CONTRACT_FIELDS]
        for r in csv.DictReader(io.TextIOWrapper(tar.extractfile("contract_items.csv"), encoding="utf-8")):
            if r["contract_id"] in rows and int(r["type_id"]) in STORE_TYPES:
                items[(r["contract_id"], r["record_id"])] = [int(r["type_id"]), int(float(r["quantity"])),
                                                              r["is_included"].lower() in ("true", "1")]
    return day, rows, items


def contracts():
    seen = {}  # contract_id -> [fields, first_seen, last_seen]
    items = {}  # (contract_id, record_id) -> [type_id, quantity, is_included]
    files = sorted((RAW / "public_contracts").rglob("*.tar.bz2"))
    with Pool() as pool:
        for n, (day, rows, its) in enumerate(pool.imap_unordered(contract_snapshot, files, chunksize=4), 1):
            items.update(its)
            if n % 100 == 0:
                print(f"contracts: {n}/{len(files)} snapshots", flush=True)
            for cid, fields in rows.items():
                s = seen.get(cid)
                if s is None:
                    seen[cid] = [fields, day, day]
                else:
                    s[1], s[2] = min(s[1], day), max(s[2], day)
    activity, corps, systems = {}, set(), set()
    f, w = out("contract", ["contract_id", "issuer_character_id", "issuer_corporation_id", "contract_type", "date_issued",
                            "issued_date", "date_expired", "price", "reward", "collateral", "volume", "region_id",
                            "solar_system_id", "first_seen", "last_seen"])
    for cid, (r, first, last) in seen.items():
        issuer, corp, issued = int(r[1]), int(r[2]) if r[2] else None, r[4]
        w.writerow([r[0], issuer, corp, r[3], issued, issued[:10], r[5], r[6], r[7], r[8], r[9], r[10] or None,
                    r[11] or None, first, last])
        a = activity.setdefault(issuer, {}).setdefault(issued[:7], [0, 0, "", None, 0])
        a[0] += 1
        a[1] |= 1 << (int(issued[8:10]) - 1)
        if issued >= a[2]:
            a[2], a[3] = issued, corp
        if corp:
            corps.add(corp)
        if r[11]:
            systems.add(int(r[11]))
    f.close()
    f, w = out("contract_item", ["contract_id", "record_id", "type_id", "quantity", "is_included"])
    for (cid, rid), (type_id, qty, included) in items.items():
        w.writerow([cid, rid, type_id, qty, included])
        if type_id == PLEX and included:
            r = seen[cid][0]
            activity[int(r[1])][r[4][:7]][4] += qty
    f.close()
    save("contracts", {"activity": activity, "corps": corps, "systems": systems})
    print(f"contracts: {len(seen):,} issued in the window, {len(activity):,} issuers, {len(items):,} store items")


# ───────────────────────── Characters, corporations, alliances ─────────────────────────

def dump_records(name):
    """Stream records of characters.json / corporations.json / alliances.json from the character dump."""
    with tarfile.open(CHAR_DUMP, "r:bz2") as tar:
        for line in tar.extractfile(f"eve-kill-com-karbowiak-2026-05-10/{name}.json"):
            line = line.strip().rstrip(b",").lstrip(b"[").rstrip(b"]")
            if line:
                yield json.loads(line)


def characters():
    km, ct = load("killmails"), load("contracts")
    scope = set(km["activity"]) | set(ct["activity"])
    boundaries = [(int(r["first_character_id"]), r["month_start"])
                  for r in csv.DictReader(open(RAW / "character_id_boundaries" / "boundaries.csv"))]
    esi = {}
    for line in open(RAW / "esi_characters" / "characters.jsonl"):
        r = json.loads(line)
        esi[r["character_id"]] = r

    def last_corp(c):
        best = ("", None)
        for src in (km["activity"].get(c, {}), ct["activity"].get(c, {})):
            for m in src.values():
                t, corp = (m[4], m[5]) if len(m) == 6 else (m[2], m[3])
                if corp and t >= best[0]:
                    best = (t, corp)
        return best[1]

    def cohort(c, signup):
        if boundaries[0][0] <= c < boundaries[-1][0]:  # created in the window: exact month from the ID boundaries
            return next(m for (lo, m), (hi, _) in zip(boundaries, boundaries[1:]) if lo <= c < hi)
        return month_of(signup) if signup else None

    rows, corps = {}, set()
    for d in dump_records("characters"):
        c = d["character_id"]
        if c in scope:
            rows[c] = d
    f, w = out("player_character", ["character_id", "character_name", "signup_date", "signup_date_source", "cohort_month",
                                    "gender", "race_id", "bloodline_id", "corporation_id", "security_status",
                                    "is_deleted", "inferred_plan", "first_omega_seen"])
    for c in sorted(scope):
        d, e = rows.get(c, {}), esi.get(c, {})
        body = e.get("body") or {}
        if (d.get("birthday") or "") >= "2003":
            signup, source = d["birthday"][:10], "dump"
        elif body.get("birthday"):
            signup, source = body["birthday"][:10], "esi"
        else:
            signup, source = None, "unknown"
        corp = body.get("corporation_id") or d.get("corporation_id") or last_corp(c) or UNKNOWN
        corps.add(corp)
        deleted = bool(d.get("deleted")) or e.get("status") == 404 or corp == DOOMHEIM
        fo = km["first_omega"].get(c)
        w.writerow([c, body.get("name") or d.get("name"), signup, source, cohort(c, signup),
                    body.get("gender") or d.get("gender"), body.get("race_id") or d.get("race_id"),
                    body.get("bloodline_id") or d.get("bloodline_id"),
                    corp, body.get("security_status", d.get("security_status")), deleted,
                    "omega" if fo else "unknown", fo])
    f.close()

    # corporations and alliances: every one referenced anywhere, placeholders for any missing from the dump
    wars = load("wars")
    corps |= km["corps"] | ct["corps"] | wars["corps"]
    corp_rows = {}
    for d in dump_records("corporations"):
        if d["corporation_id"] in corps:
            corp_rows[d["corporation_id"]] = d
    alliances = km["alliances"] | wars["alliances"] | {d["alliance_id"] for d in corp_rows.values() if d.get("alliance_id")}
    f, w = out("alliance", ["alliance_id", "alliance_name", "ticker", "date_founded", "executor_corporation_id"])
    found = set()
    for d in dump_records("alliances"):
        if d["alliance_id"] in alliances:
            w.writerow([d["alliance_id"], d.get("name"), d.get("ticker"), d.get("date_founded"), d.get("executor_corporation_id")])
            found.add(d["alliance_id"])
    for a in sorted(alliances - found):
        w.writerow([a, None, None, None, None])
    f.close()
    f, w = out("corporation", ["corporation_id", "corporation_name", "ticker", "alliance_id", "date_founded", "member_count", "is_npc"])
    for c in sorted(corps):
        d = corp_rows.get(c, {})
        w.writerow([c, d.get("name") if c != UNKNOWN else "Unknown", d.get("ticker"), d.get("alliance_id"),
                    d.get("date_founded"), d.get("member_count"), c < 2000000])
    f.close()
    print(f"characters: {len(scope):,} in scope ({len(rows):,} in the dump), {len(corps):,} corporations, {len(alliances):,} alliances")


# ───────────────────────── Activity and signups ─────────────────────────

def activity():
    km, ct = load("killmails"), load("contracts")
    npc = {}
    with gzip.open(CLEAN / "corporation.csv.gz", "rt") as f:
        for r in csv.DictReader(f):
            npc[int(r["corporation_id"])] = r["is_npc"] == "True"
    f, w = out("character_month_activity", ["character_id", "month", "kills", "losses", "contracts_issued",
                                            "active_days", "flew_omega_ship", "plex_offered", "in_player_corporation"])
    for c in sorted(set(km["activity"]) | set(ct["activity"])):
        kms, cts = km["activity"].get(c, {}), ct["activity"].get(c, {})
        for month in sorted(set(kms) | set(cts)):
            k = kms.get(month, [0, 0, 0, False, "", None])
            t = cts.get(month, [0, 0, "", None, 0])
            corp = k[5] if k[4] >= t[2] else t[3]
            w.writerow([c, month + "-01", k[0], k[1], t[0], bin(k[2] | t[1]).count("1"), k[3], t[4],
                        None if corp is None else not npc.get(corp, True)])
    f.close()

    b = [r for r in csv.DictReader(open(RAW / "character_id_boundaries" / "boundaries.csv"))]
    f, w = out("character_signup_month", ["month", "first_character_id", "characters_created"])
    for cur, nxt in zip(b, b[1:]):
        w.writerow([cur["month_start"], cur["first_character_id"], int(nxt["first_character_id"]) - int(cur["first_character_id"])])
    f.close()
    print("activity: character_month_activity and character_signup_month written")


# ───────────────────────── Phase 2 ─────────────────────────

def sources():
    """source_document: one row per raw file in data/raw/sources.csv (its row number is the id)."""
    ids = {}
    f, w = out("source_document", ["source_id", "source_name", "publisher", "url", "retrieved_at", "sha256", "data_nature"])
    for i, r in enumerate(csv.DictReader(open(RAW / "sources.csv")), 1):
        if r["file"] in ids:  # a file re-logged by a later run: keep the first entry
            continue
        ids[r["file"]] = i
        w.writerow([i, r["source"], r["publisher"], r["url"], r["retrieved_at"], r["sha256"], r["data_nature"]])
    f.close()
    save("sources", ids)
    print(f"sources: {len(ids):,} documents")


def source_id(path):
    return load("sources")[str(Path(path).relative_to(RAW))]


def market_day(path):
    rows = []
    with bz2.open(path, "rt") as f:
        for r in csv.DictReader(f):
            if int(r["type_id"]) in STORE_TYPES:
                rows.append([r["date"], r["region_id"], r["type_id"], r["average"], r["highest"], r["lowest"],
                             r["volume"], r["order_count"]])
    return rows


def market():
    files = [p for p in sorted((RAW / "market_history").rglob("*.csv.bz2")) if START <= date.fromisoformat(p.name[15:25]) <= END]
    f, w = out("market_history_daily", ["date", "region_id", "type_id", "average_price", "highest_price", "lowest_price",
                                        "volume", "order_count"])
    n = 0
    with Pool() as pool:
        for rows in pool.imap_unordered(market_day, files, chunksize=8):
            w.writerows(rows)
            n += len(rows)
    f.close()
    print(f"market: {n:,} rows for the store items")


def players_online():
    """Daily average / peak / min concurrent players, and minutes of outage outside the 11:00 UTC downtime."""
    by_day = {}
    for path in sorted((RAW / "players_online").glob("*.jsonp")):
        s = path.read_text()
        for ms, players in json.loads(s[s.index("["):s.rindex("]") + 1]):
            t = datetime.utcfromtimestamp(ms / 1000)
            by_day.setdefault(t.date(), []).append((t, players))
    f, w = out("players_online_daily", ["date", "avg_players", "peak_players", "min_players", "outage_minutes"])
    for d, points in sorted(by_day.items()):
        if d > END:  # history runs from 2006-06, before START, for the "23 years of EVE" chart
            continue
        values = [p for _, p in points]
        up_slots = {(t.hour, t.minute // 30) for t, p in points if p > 0}
        expected = {(h, m) for h in range(24) for m in (0, 1) if h != 11}  # 11:00-12:00 UTC is daily downtime
        w.writerow([d, round(sum(values) / len(values)), max(values), min(values), 30 * len(expected - up_slots)])
    f.close()
    print(f"players_online: {len(by_day):,} days")


def append_alliances(ids):
    """Placeholder alliance rows for referenced alliances missing from the dump (idempotent)."""
    missing = set(ids) - existing_ids("alliance")
    with gzip.open(CLEAN / "alliance.csv.gz", "at", newline="") as f:
        csv.writer(f).writerows([a, None, None, None, None] for a in sorted(missing))
    return len(missing)


def sov_campaigns():
    seen = {}  # campaign_id -> [campaign, first_seen, last_seen]
    for path in sorted((RAW / "sovereignty_campaigns").rglob("*.json.bz2")):
        stamp = path.name[22:32] + "T" + path.name[33:41].replace("-", ":")  # sovereignty-campaigns-YYYY-MM-DD_HH-MM-SS
        for c in json.loads(bz2.decompress(path.read_bytes())):
            s = seen.get(c["campaign_id"])
            if s is None:
                seen[c["campaign_id"]] = [c, stamp, stamp]
            else:
                s[0], s[2] = c, max(s[2], stamp)
                s[1] = min(s[1], stamp)
    f, w = out("sov_campaign", ["campaign_id", "event_type", "solar_system_id", "defender_alliance_id", "structure_id",
                                "start_time", "first_seen", "last_seen", "final_attackers_score", "final_defender_score"])
    for c, first, last in seen.values():
        w.writerow([c["campaign_id"], c["event_type"], c["solar_system_id"], c.get("defender_id"), c.get("structure_id"),
                    c["start_time"], first, last, c.get("attackers_score"), c.get("defender_score")])
    f.close()
    added = append_alliances({c.get("defender_id") for c, _, _ in seen.values() if c.get("defender_id")})
    print(f"sov_campaigns: {len(seen):,} campaigns ({added} placeholder alliances)")


def sovereignty():
    f, w = out("sovereignty_daily", ["date", "solar_system_id", "alliance_id"])
    alliances, days = set(), 0
    for path in sorted((RAW / "sovereignty_map").rglob("*.json.bz2")):
        day = path.name[16:26]  # sovereignty-map-YYYY-MM-DD_...
        for r in json.loads(bz2.decompress(path.read_bytes())):
            if r.get("alliance_id"):
                w.writerow([day, r["system_id"], r["alliance_id"]])
                alliances.add(r["alliance_id"])
        days += 1
    f.close()
    print(f"sovereignty: {days} days, {len(alliances)} alliances ({append_alliances(alliances)} placeholder alliances)")


def steam():
    seen = {}
    for path in sorted((RAW / "steam_reviews").glob("*.json")):
        for r in json.loads(path.read_text())["reviews"]:
            seen[r["recommendationid"]] = r
    f, w = out("steam_review", ["recommendation_id", "steam_author_id", "created_date", "language", "voted_up",
                                "playtime_at_review_hours", "steam_purchase", "received_for_free", "votes_up", "review_text"])
    for r in seen.values():
        a = r["author"]
        w.writerow([r["recommendationid"], a["steamid"], datetime.utcfromtimestamp(r["timestamp_created"]).date(),
                    r["language"], r["voted_up"],
                    round(a["playtime_at_review"] / 60, 1) if a.get("playtime_at_review") is not None else None,
                    r.get("steam_purchase"), r.get("received_for_free"), r.get("votes_up"), r.get("review")])
    f.close()
    print(f"steam: {len(seen):,} reviews")


def strip_html(html):
    import html as h
    import re
    return h.unescape(re.sub(r"<[^>]+>", " ", html or "")).strip()


def forums():
    sys.path.insert(0, str(ROOT / "scripts"))
    from download import FORUM_TITLE_FILTER
    query_of = {}
    for path in sorted((RAW / "forums" / "search").glob("*.json")):
        query = path.name.rsplit("_page_", 1)[0].replace("_", " ")
        for t in json.loads(path.read_text()).get("topics", []):
            query_of.setdefault(t["id"], query)
    topics, posts = {}, {}
    for path in sorted((RAW / "forums" / "topics").glob("*.json")):
        t = json.loads(path.read_text())
        if not FORUM_TITLE_FILTER.search(t.get("title", "")):  # off-topic threads fetched before the filter
            continue
        topics[t["id"]] = t
        for p in t.get("post_stream", {}).get("posts", []):
            posts[p["id"]] = p
    f, w = out("forum_topic", ["topic_id", "title", "created_date", "posts_count", "matched_query"])
    for t in topics.values():
        w.writerow([t["id"], t["title"], t["created_at"][:10], t.get("posts_count"), query_of.get(t["id"])])
    f.close()
    f, w = out("forum_post", ["post_id", "topic_id", "created_date", "author_hash", "post_text"])
    for p in posts.values():
        if p.get("topic_id") in topics:
            w.writerow([p["id"], p["topic_id"], p["created_at"][:10],
                        hashlib.sha256(p.get("username", "").encode()).hexdigest(), strip_html(p.get("cooked"))])
    f.close()
    print(f"forums: {len(topics):,} topics, {len(posts):,} posts")


def fx():
    f, w = out("fx_rate", ["date", "currency_pair", "rate"])
    for series, pair in (("DEXKOUS", "KRW/USD"), ("DEXUSEU", "USD/EUR")):
        for r in csv.DictReader(open(RAW / "fx" / f"{series}.csv")):
            d, v = r["observation_date"], r[series]
            if v not in ("", ".") and "1997-01-01" <= d <= "2026-12-31":
                w.writerow([d, pair, v])
    f.close()
    print("fx: written")


def economy():
    """MER (latest): money supply, ISK sinks and faucets by category, mined/produced/destroyed value by security band."""
    totals = {}
    with zipfile.ZipFile(MER) as z:
        def rows(name):
            return csv.DictReader(io.TextIOWrapper(z.open(f"data/{name}.csv"), encoding="utf-8"))
        for r in rows("money_supply"):
            for k in ("character_isk", "corporation_isk", "total_isk", "isk_velocity"):
                totals[(r["history_date"], k)] = float(r[k])
        for r in rows("sinks_and_faucets_history"):
            for kind, col in (("sink", "entry_sink_value"), ("faucet", "entry_faucet_value")):
                key = (r["history_date"], f"{kind}:{r['entry_name']}")
                totals[key] = totals.get(key, 0) + float(r[col] or 0)
        for r in rows("mining_production_destruction"):
            for k in ("mined_value", "produced_value", "destroyed_value"):
                key = (r["history_date"], f"{k}:{r['location_metagroup']}")
                totals[key] = totals.get(key, 0) + float(r[k] or 0)
    f, w = out("economy_daily", ["date", "metric", "value"])
    for (d, metric), v in sorted(totals.items()):
        w.writerow([d, metric, v])
    f.close()
    print(f"economy: {len(totals):,} daily figures")


def parse_num(text):
    """'515.6 thousand' -> 515600, '1.5 million' -> 1500000, '693' -> 693."""
    n, _, unit = text.replace(",", "").strip().partition(" ")
    return float(n) * {"thousand": 1e3, "million": 1e6, "billion": 1e9}.get(unit.strip(), 1)


def steam_months(path):
    """(month, average players, peak players) rows from a SteamCharts app page; the current partial month is skipped."""
    import re
    return re.findall(r'month-cell left">\s*([A-Z][a-z]+ \d{4})\s*</td>\s*<td class="right num-f">([\d.]+)</td>'
                      r'.*?<td class="right num">(\d+)</td>', path.read_text(), flags=re.S)


def interest():
    import re
    f, w = out("interest_metric", ["period_start", "granularity", "source", "metric", "geography", "value", "source_id"])
    trends = RAW / "google_trends"
    sid = source_id(trends / "eve_online_worldwide_weekly.csv")
    for row in list(csv.reader(open(trends / "eve_online_worldwide_weekly.csv")))[3:]:
        if row and row[1]:
            w.writerow([row[0], "week", "google_trends", "search_interest", "Worldwide", 0.5 if row[1] == "<1" else row[1], sid])
    sid = source_id(trends / "eve_online_by_country.csv")
    for row in list(csv.reader(open(trends / "eve_online_by_country.csv")))[3:]:
        if row and row[1]:
            w.writerow([START, "period", "google_trends", "search_interest", row[0], 0.5 if row[1] == "<1" else row[1], sid])
    path = RAW / "steam_players" / "steamcharts_8500.html"
    sid = source_id(path)
    for month, avg, peak in steam_months(path):
        d = datetime.strptime(month, "%B %Y").date()
        w.writerow([d, "month", "steam", "avg_players", "Worldwide", avg, sid])
        w.writerow([d, "month", "steam", "peak_players", "Worldwide", peak, sid])
    labels = {"Hours watched": "hours_watched", "Hours streamed": "hours_streamed", "Average viewers": "avg_viewers",
              "Max viewers": "peak_viewers", "Streamers": "streamers", "Average channels": "avg_channels"}
    for path in sorted((RAW / "twitch").glob("sullygnome_20??-??.html")):
        t = re.sub(r"<script.*?</script>|<style.*?</style>", "", path.read_text(errors="ignore"), flags=re.S)
        t = re.sub(r"\s*\|[\s|]*", "|", re.sub(r"<[^>]+>", "|", t))
        sid = source_id(path)
        for label, metric in labels.items():
            m = re.search(re.escape(label) + r"\|([^|]+)", t)
            if m:
                w.writerow([path.stem.split("_")[1] + "-01", "month", "twitch", metric, "Worldwide", parse_num(m.group(1)), sid])
    f.close()
    print("interest: written")


def game_events():
    import re
    f, w = out("game_event", ["event_id", "event_date", "date_precision", "category", "title", "source_id", "source_ref"])
    n = 0

    def add(d, precision, category, title, sid, ref):
        nonlocal n
        n += 1
        w.writerow([n, d, precision, category, title, sid, ref])

    for path in sorted((RAW / "patch_history").glob("patch_notes_page_*.json")):
        sid = source_id(path)
        for i in json.loads(path.read_text())["items"]:
            fl = i["fields"]
            add(fl["publishingDate"][:10], "day", "patch", fl["title"], sid, fl["slug"])
    for path in sorted((RAW / "patch_history").glob("sde_builds_*.json")):
        sid = source_id(path)
        for fl in json.loads(path.read_text()).get("files", []):
            m = re.search(r"(\d{6,})", fl["name"])
            if fl["name"].endswith("jsonl.zip") or (fl["name"].endswith(".zip") and "yaml" not in fl["name"]):
                add(fl["last_modified"][:10], "day", "deployment", f"Static data build {m.group(1) if m else fl['name']}", sid, fl["name"])
    path = RAW / "patch_history" / "eveuni_expansions.html"
    sid = source_id(path)
    for name, day in re.findall(r"<b>\s*([^<]+?)\s*</b></span><br>\s*<b>Initial Release Date:</b>\s*(\d{2}/\d{2}/\d{4})", path.read_text()):
        d = datetime.strptime(day, "%d/%m/%Y").date()
        add(d, "day", "release" if re.match(r"^\d+\.\d+ Release$", name) else "expansion", name, sid, name)
    transcript_sid = source_id(RAW / "qualitative" / "down_the_rabbit_hole_BCSeISYcoyI.json")
    for r in csv.DictReader(open(ROOT / "data" / "reference" / "lore_events.csv")):
        add(r["date"], r["precision"], "lore", r["event"], transcript_sid, r["video_timestamp"])
    for r in csv.DictReader(open(ROOT / "data" / "reference" / "key_events.csv")):
        add(r["date"], r["precision"], r["category"], r["title"], source_id(RAW / r["source_file"]), r["source_file"])
    f.close()
    print(f"game_events: {n:,}")


# ───────────────────────── Phase 3: curated reference data ─────────────────────────

def curated():
    """financial_metric, plan, plan_price and benchmark_metric from the hand-curated files in data/reference/
    (each row cites its raw file; the CSVs also keep the page number)."""
    ref = ROOT / "data" / "reference"
    f, w = out("financial_metric", ["metric_id", "period_start", "period_end", "granularity", "entity", "metric",
                                    "geography", "amount", "currency", "source_id"])
    for i, r in enumerate(csv.DictReader(open(ref / "financial_metrics.csv")), 1):
        w.writerow([i, r["period_start"], r["period_end"], r["granularity"], r["entity"], r["metric"],
                    r["geography"] or None, r["amount"], r["currency"], source_id(RAW / r["source_file"])])
    f.close()

    prices = list(csv.DictReader(open(ref / "plan_prices.csv")))
    plan_ids = {}
    f, w = out("plan", ["plan_id", "plan_name", "product_type", "billing_cycle_months"])
    for r in prices:
        if r["plan_name"] not in plan_ids:
            plan_ids[r["plan_name"]] = len(plan_ids) + 1
            w.writerow([plan_ids[r["plan_name"]], r["plan_name"], r["product_type"], r["billing_cycle_months"] or None])
    f.close()
    f, w = out("plan_price", ["plan_id", "effective_date", "currency", "list_price", "sale_price", "source_id"])
    for r in prices:
        w.writerow([plan_ids[r["plan_name"]], r["effective_date"], r["currency"], r["list_price"], r["sale_price"] or None,
                    source_id(RAW / r["source_file"])])
    f.close()

    f, w = out("benchmark_metric", ["benchmark_id", "game", "metric", "value", "unit", "period", "source_id"])
    for i, r in enumerate(csv.DictReader(open(ref / "benchmarks.csv")), 1):
        w.writerow([i, r["game"], r["metric"], r["value"], r["unit"], r["period"], source_id(RAW / r["source_file"])])
    # Steam staying power: average players 12 months after the month with the all-time peak, as a share of that month
    games = {8500: "EVE Online", 306130: "The Elder Scrolls Online", 39210: "Final Fantasy XIV", 582660: "Black Desert",
             1343400: "RuneScape", 1343370: "Old School RuneScape", 1063730: "New World", 1599340: "Lost Ark",
             2429640: "Throne and Liberty", 761890: "Albion Online", 1284210: "Guild Wars 2"}
    for app, game in games.items():
        path = RAW / "steam_players" / f"steamcharts_{app}.html"
        months = {datetime.strptime(m, "%B %Y").date(): (float(avg), int(peak)) for m, avg, peak in steam_months(path)}
        peak_month = max(months, key=lambda m: months[m][1])
        later = peak_month.replace(year=peak_month.year + 1)
        rows = [("steam_all_time_peak_players", months[peak_month][1], "players"),
                ("steam_avg_players_peak_month", months[peak_month][0], "players")]
        if later in months:
            rows.append(("steam_share_of_peak_month_after_12_months", round(months[later][0] / months[peak_month][0], 4),
                         "share of peak-month average players"))
        for metric, value, unit in rows:
            i += 1
            w.writerow([i, game, metric, value, unit, f"peak month {peak_month:%Y-%m}", source_id(path)])
    f.close()
    print(f"curated: {i} benchmarks, {len(plan_ids)} plans, {len(prices)} prices")


STEPS = {"dimensions": dimensions, "wars": wars, "killmails": killmails, "placeholders": placeholders,
         "contracts": contracts, "characters": characters, "activity": activity,
         "sources": sources, "market": market, "players_online": players_online, "sov_campaigns": sov_campaigns, "sovereignty": sovereignty,
         "steam": steam, "forums": forums, "fx": fx, "economy": economy, "interest": interest, "game_events": game_events,
         "curated": curated}

if __name__ == "__main__":
    for step in (STEPS if sys.argv[1] == "all" else [sys.argv[1]]):
        STEPS[step]()
