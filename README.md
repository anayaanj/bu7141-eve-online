# BU7141 — EVE Online subscription KPIs

Group project for BU7141 Data Management & Visualisation (TCD). We use public EVE Online data to model a subscription business: acquisition, engagement, retention, monetization and satisfaction.

**Story:** what can public data reveal about a subscription game? Player activity is per player (killmails, characters). Money is company level only (CCP's accounts, Pearl Abyss reports, the PLEX market).

## Repo layout

```
scripts/download.py       downloads every source into data/raw/ and logs it
data/raw/sources.csv      log of every downloaded file: URL, date, size, sha256
data/raw/financials/      CCP and Pearl Abyss reports (committed: hard to re-fetch)
data/raw/<everything else> not in git (6.4 GB): re-create with the script
docs/raw_inventory.md     field-level description of every source (use it for the ERD)
docs/eve-online-brief.pdf one-page team brief: sources, KPI coverage, caveats
data-sourcing-guide.docx  the assignment's data sourcing guide
```

## Setup

Needs Python 3.10+ only (no packages to install).

```bash
git clone https://github.com/anayaanj/bu7141-eve-online.git
cd bu7141-eve-online
export CONTACT_EMAIL=you@tcd.ie   # CCP asks API users to include a contact
```

## How to make changes

`main` is protected: nobody can push to it directly, admins included. Every change goes through a pull request that **one other teammate** approves.

```bash
git checkout main && git pull
git checkout -b your-name/short-description   # e.g. maria/erd-draft
# ...make your changes...
git add <files> && git commit -m "Describe the change"
git push -u origin HEAD
gh pr create --fill                            # or open the PR on github.com
```

- You can't approve your own pull request. Ask a teammate to review it.
- If you push new commits after an approval, the approval resets and the PR needs a fresh review.
- Resolve every review comment before merging.

## ERD

- **View:** https://dbdiagram.io/d/6abf9f99abcc87fb7ad472c6
- **Source:** `docs/erd.dbml`. The repo is linked to the diagram in `.dbdiagram/settings.json`.
- **Setup once:** `npm install -g dbdiagram`, then `dbdiagram auth login`.

| You changed… | Run | Then |
|---|---|---|
| the diagram on dbdiagram.io | `dbdiagram pull` | Commit `docs/erd.dbml` on a branch and open a pull request |
| `docs/erd.dbml` locally | `dbdiagram validate`, then `dbdiagram push` | Open a pull request |

Pull before you edit, so you don't overwrite someone else's changes on the diagram.

## Get the raw data

Run each command from the repo root. Each one skips files you already have, so if one stops, run it again.

| Command | What it downloads | Size | Time |
|---|---|---|---|
| `python3 scripts/download.py characters` | Character dump | 860 MB | ~10 min |
| `python3 scripts/download.py killmails` | Daily killmails, Jan 2024 – Aug 2026 | 2.6 GB | ~1 h |
| `python3 scripts/download.py market` | Daily market history | 540 MB | ~30 min |
| `python3 scripts/download.py mer` | CCP Monthly Economic Reports | 2.3 GB | ~30 min |
| `python3 scripts/download.py steam` | Steam reviews | 43 MB | ~15 min |
| `python3 scripts/download.py pricing` | Omega and store page snapshots | 6 MB | ~10 min |
| `python3 scripts/download.py news` | CCP news articles on Omega and PLEX | 15 MB | 1 min |
| `python3 scripts/download.py esi_characters` | Real creation dates for killmail characters | 60 MB | ~2 h |

- **Order:** `esi_characters` needs `killmails` and `characters` first.
- **Long jobs:** on a Mac, put `caffeinate -i` in front of a command to keep the computer awake while it runs.
- **`sources.csv`:** your downloads add rows to it. The committed version is the official log of our retrieval, so **don't commit your changes to it**. Undo them with `git checkout data/raw/sources.csv`.

## Where the data comes from

All sources are real and public. Retrieved 28 Sep – 1 Oct 2026; exact URLs and times are in `sources.csv`.

| Source | Publisher | How we got it |
|---|---|---|
| Killmails | zKillboard / CCP ESI, archived by [EVE Ref](https://data.everef.net/killmails/) | Daily `.tar.bz2` archives |
| Characters | [eve-kill.com](https://eve-kill.com), mirrored by EVE Ref | One snapshot (2026-05-10) |
| ESI characters | CCP, [ESI API](https://esi.evetech.net) | One request per character with no real birthday in the dump |
| Market history | CCP ESI, archived by [EVE Ref](https://data.everef.net/market-history/) | Daily CSVs; PLEX is `type_id` 44992 |
| Monthly Economic Reports | CCP, mirrored by [EVE Ref](https://data.everef.net/ccp/mer/) | Monthly zips of charts and CSVs |
| Steam reviews | Valve, [Steam reviews API](https://store.steampowered.com/appreviews/8500?json=1) (app 8500) | Paged through every review |
| Pricing pages | CCP, archived by the [Wayback Machine](https://web.archive.org) | First snapshot per month of the Omega and store pages |
| News articles | CCP, the content API behind eveonline.com | Articles matching "omega" or "plex", 2023 onward |
| Pearl Abyss reports | [Pearl Abyss IR](https://www.pearlabyss.com/en-US/IR/Data/Performance) | `download.py pearl_abyss`: earnings releases, IR letters, financial page |
| CCP annual accounts | [Skatturinn](https://www.skatturinn.is/fyrirtaekjaskra/leit/kennitala/4506973469) (Iceland Revenue and Customs) | Ordered free through the site's web shop (FY2022–2025), logged with `download.py financials` |

## What each object is

The full fields, keys and data quality notes are in [`docs/raw_inventory.md`](docs/raw_inventory.md).

| Object | One row is… | Key | Used for |
|---|---|---|---|
| Killmail | one ship destroyed, with its victim and attackers | `killmail_id` | Engagement, retention (who was active when) |
| Character | one player character | `character_id` | Customer, acquisition (`birthday` = signup date) |
| ESI character | one character's official record from CCP | `character_id` | Fills in missing birthdays |
| Market history | one item type, in one region, on one day | `date, region_id, type_id` | Monetization (PLEX price and volume) |
| MER CSVs | one day or month of an economy indicator | varies by file | Monetization, economy context |
| Steam review | one user review | `recommendationid` | Satisfaction |
| Pricing page / news article | one page snapshot or announcement | file / `sys.id` | Plan (Omega and PLEX prices) |
| Pearl Abyss report | one quarter | quarter | Monetization (EVE revenue to 4Q25) |
| CCP annual accounts | one fiscal year | year | Monetization (audited revenue, deferred subscriptions) |

## KPI coverage vs. the sourcing guide

We cover 12 of the guide's 15 KPIs: 2 directly, 6 by proxy and 4 as company-level estimates. Keep the estimates visually separate from official figures in the dashboard.

| Category | KPI | Coverage | How | Gap |
|---|---|---|---|---|
| Acquisition | Signups | ✅ Direct | Characters by creation month (`birthday`); 97.8% coverage for killmail characters | One account can have several characters |
| Acquisition | CAC | ⚠️ Estimate | CCP marketing expense ($11.4M 2024, $16.1M 2025) ÷ new characters | Marketing covers all CCP games, so it overstates EVE's CAC |
| Acquisition | Conversion rate | ❌ None | — | No public Alpha → Omega funnel data |
| Engagement | DAU / MAU | 🔶 Proxy | Distinct characters in killmails per day / 30 days | Only players who fight; no login data |
| Engagement | Session frequency | 🔶 Proxy | Days with combat activity per character per week | Not real sessions |
| Engagement | Feature adoption | 🔶 Proxy | Ship class, security band, fleet size | Combat only |
| Retention | Retention rate | 🔶 Proxy | Character still active in killmails N months later | Activity, not subscription |
| Retention | Churn rate | 🔶 Proxy | No killmails for N months | A player who stops fighting isn't necessarily unsubscribed |
| Retention | Cohort trends | ✅ Direct | Creation-month cohorts × monthly killmail activity | Same activity caveat |
| Monetization | MRR / ARR | ⚠️ Estimate | CCP subscriptions and in-game sales ($55.0M 2024, $60.8M 2025); Pearl Abyss quarterly EVE revenue to 4Q25 | Annual / quarterly, not per subscriber |
| Monetization | ARPU | ⚠️ Estimate | Revenue ÷ active characters | Overstated: active = only those who fight |
| Monetization | LTV | ⚠️ Estimate | ARPU × average lifespan from cohort curves | Inherits both caveats |
| Satisfaction | NPS | 🔶 Proxy | Steam reviews, % positive vs. negative by month | Recommend yes/no, not a 0–10 score |
| Satisfaction | CSAT | ❌ None | — | No public surveys |
| Satisfaction | Support tickets | ❌ None | — | No public ticket data |

**Suggested focus:** build the story on Retention and Engagement (per-player cohort curves) and check them against Monetization (CCP's audited revenue and the PLEX market). The guide treats the missing KPIs as a valid ERD-boundary discussion.

## Things to know

- **No per-player payments exist publicly.** Monetization is company level only. This is our ERD boundary.
- **Killmails only show players who fight**, so retention measured from them is a lower bound.
- **Pearl Abyss sold CCP to CCP's management on 1 May 2026**, and CCP renamed itself Fenris Creations. Pearl Abyss's EVE revenue series ends at 4Q25.
- **2026-07-13 has no killmails.** The file is missing at the source, not in our download.
