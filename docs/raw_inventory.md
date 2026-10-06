# Raw data inventory

Window: 2024-01-01 → 2026-08-31. Retrieved 2026-09-28. Every file is logged in `data/raw/sources.csv` (URL, retrieved_at, bytes, sha256). Files are untouched as downloaded.

## 1. Killmails — `data/raw/killmails/YYYY/killmails-YYYY-MM-DD.tar.bz2`
- **Publisher:** zKillboard / CCP ESI, archived by EVE Ref. Real, public game events.
- **Volume:** 973 daily archives, 2.6 GB compressed, ~23k killmails/day (~22M total).
- **Grain:** one JSON file per killmail (`killmails/<killmail_id>.json`).
- **Fields:**
  - `killmail_id` (int, PK), `killmail_hash`, `killmail_time` (ISO UTC), `solar_system_id`, `war_id` (rare), `moon_id` (rare), `http_last_modified`
  - `victim`: `character_id` (missing when an NPC/structure dies), `corporation_id`, `alliance_id`, `faction_id`, `ship_type_id`, `damage_taken`, `position{x,y,z}`, `items[]` (`item_type_id`, `flag`, `quantity_dropped` / `quantity_destroyed`, `singleton`)
  - `attackers[]`: `character_id` (missing for NPCs), `corporation_id`, `alliance_id`, `faction_id`, `ship_type_id`, `weapon_type_id`, `damage_done`, `final_blow`, `security_status`
- **Gaps:** 2026-07-13 missing upstream (404 at EVE Ref). Only covers players who get into fights.

## 2. Characters — `data/raw/characters/eve-kill-com-karbowiak-2026-05-10.tar.bz2`
- **Publisher:** eve-kill.com (Karbowiak), mirrored by EVE Ref. Snapshot 2026-05-10. Real, public character records.
- **Contents:** `characters.json`, `corporations.json`, `alliances.json` (JSON arrays, one record per line).
- **Grain (characters):** one row per character. 20,826,709 records.
- **Fields:** `character_id` (PK), `name`, `description`, `birthday`, `gender`, `race_id`, `bloodline_id`, `security_status`, `corporation_id`, `alliance_id`, `faction_id`, `deleted`, `last_active`, `createdAt`/`updatedAt` (eve-kill's own timestamps), `history[]` (corporation history).
- **Quality:**
  - ~16.0M records have a placeholder `birthday` (1968–1977, i.e. ~1970-01-01); 3,591 have none. ~4.8M have a real birthday.
  - 2025 has 671k births (≈3.5× a normal year) — to investigate.
  - 2026 is partial (snapshot is May, and characters are only recorded once seen).
  - `last_active` filled for 14%; `deleted` = true for 2.86M; `history` non-empty for 1.41M.

## 2b. ESI character records — `data/raw/esi_characters/`
- **Publisher:** CCP Games, ESI API (`/characters/{id}/`). Real, official. Retrieved 2026-09-28 → 2026-10-01.
- **Why:** of the 838,881 unique characters in the killmails, 137,521 had no real birthday in the character dump. These are the ones looked up.
- **Files:** `character_ids_to_fetch.txt` (the 137,521 ids), `characters.jsonl` (one line per id: `character_id`, `status`, `retrieved_at`, `body`).
- **Results:** 119,334 found (HTTP 200); 18,187 not found (HTTP 404: deleted or biomassed characters).
- **Fields (`body`):** `birthday`, `name`, `gender`, `race_id`, `bloodline_id`, `corporation_id`, `alliance_id` (32%), `faction_id` (8%), `security_status`, `title` (8%), `description`.
- **Birthdays found:** mostly recent. 2026: 46,368 (characters created after the May 2026 dump); 2024: 17,704; 2025: 9,874; the rest spread over 2003–2023.
- **Combined coverage:** 701,360 killmail characters have a real birthday in the dump, plus 119,334 from ESI, gives 820,694 of 838,881 (97.8%). 18,187 (2.2%) have no birthday.

## 3. Market history — `data/raw/market_history/YYYY/market-history-YYYY-MM-DD.csv.bz2`
- **Publisher:** CCP ESI, archived by EVE Ref. Real, daily aggregates.
- **Volume:** 974 daily files, ~56k rows/day.
- **Grain:** one row per `(date, region_id, type_id)`.
- **Columns:** `average, date, highest, lowest, order_count, volume, http_last_modified, region_id, type_id`
- **PLEX:** `type_id = 44992`, traded in ~40 regions/day; ~6.0M ISK in June 2025 (The Forge, region 10000002, is the main hub).

## 4. Monthly Economic Report (MER) — `data/raw/mer/*.zip`
- **Publisher:** CCP Games, mirrored by EVE Ref. Real, official aggregates.
- **Volume:** 33 zips (Jan 2024 → Aug 2026; July 2024 exists twice: `Jul2024` and `Jul2024v2`). Naming changes from `MonYYYY` to `YYYYMM` in Aug 2025.
- **Contents:** charts (`.html`/`.png`) plus `data/*.csv`. Each CSV holds **full history**, not just that month (e.g. `money_supply` from 2017).
- **Most relevant CSVs:**
  | CSV | Grain | Columns |
  |---|---|---|
  | `money_supply` | day | `history_date, character_isk, corporation_isk, total_isk, isk_velocity, isk_velocity_wo_accessories` |
  | `sinks_and_faucets_history` | day × entry | `history_date, entry_id, entry_name, entry_sink_value, entry_faucet_value` |
  | `commodity_sinks_and_faucets_history` | day × group | `history_date, group_id, group_name, group_value` |
  | `mining_production_destruction` | day × security band | `history_date, location_metagroup, mined_value, produced_value, destroyed_value` |
  | `economy_indices_details` | month × index | `history_date, primary_index, sub_index, price_change, total_value, price_change_weighted` |
  | `kill_dump` | kill (that month) | `kill_datetime, kill_solarsystem_id, victim/killer ship, corporation, alliance, faction ids, ccp_isk_lost, ccp_isk_destroyed, zkb_isk_*` (no character ids) |
  | `key_economic_figures_by_region` | region (that month) | `region_name, destroyed_value, mined_value, produced_value, trade_value, loyalty_points, npc_bounties` |
  | `static_solarsystems`, `static_type_values` | reference | lookup tables |

## 5. Steam reviews — `data/raw/steam_reviews/reviews_page_NNNN.json`
- **Publisher:** Valve / Steam, `appreviews/8500` API. Real, public user reviews.
- **Volume:** 396 pages, 39,555 unique reviews (Steam summary reports 39,557, 29,012 positive / 10,545 negative).
- **Grain:** one review per `recommendationid` (PK).
- **Fields:** `recommendationid`, `language`, `review` (text), `timestamp_created`/`timestamp_updated` (unix), `voted_up` (bool), `votes_up`, `votes_funny`, `weighted_vote_score`, `comment_count`, `steam_purchase`, `received_for_free`, `refunded`, `written_during_early_access`, `primarily_steam_deck`, `author{steamid, num_games_owned, num_reviews, playtime_forever, playtime_last_two_weeks, playtime_at_review, last_played}` (minutes / unix)
- **Note:** a Steam account doesn't link to an EVE character, so Satisfaction stays a separate entity.

## 6. Pricing pages — `data/raw/pricing/*.html`
- **Publisher:** CCP Games, archived by the Internet Archive (Wayback Machine). First snapshot per month.
- **Volume:** 33 snapshots per page (Jan 2024 → Sep 2026).
- **Pages:** `www.eveonline.com/omega` (only shows "$9.00 and up"; the full price table loads with JavaScript) and `store.eveonline.com/`.
- **Store snapshots with prices in the HTML:** 7 of 33 (2024-01, 2024-02, 2024-05, 2024-07, 2024-09, 2024-12, 2026-03). They include sale prices (strikethrough) as well as list prices. The rest load prices with JavaScript.
- **Gap:** full Plan prices will likely need CCP's price-change announcements as an extra source.

## 7. CCP news articles — `data/raw/news/{omega,plex}_page_NNN.json`
- **Publisher:** CCP Games, from the Contentful API behind eveonline.com (the public read-only token in the site's JavaScript). Real, official announcements.
- **Volume:** 320 unique articles, Jan 2023 → Sep 2026 (214 match "omega", 233 match "plex"; the two sets overlap).
- **Grain:** one article per `sys.id`. **Fields:** `title`, `slug`, `category`, `author`, `publishingDate`, `metaDescription`, `tags`, `content` / `richText` (article body).
- **Prices:** 30 articles contain dollar amounts. The key one is "Value Over FOMO: Omega, You, and Store Clean Up" (2025-07-25), which lists Omega prices ($11.24–$12.99/month). Sale articles give list and discounted prices.

## 8. Financials — `data/raw/financials/`
### Pearl Abyss — `pearl_abyss/` (scripted, `download.py pearl_abyss`)
- **Publisher:** Pearl Abyss Corp. investor relations (pearlabyss.com/en-US/IR). Real, official.
- **Files:** `performance/` — 13 quarterly earnings releases, 2Q23 → 2Q26 (1Q23 has no English attachment). `letter/` — 32 monthly IR letters, Jan 2024 → Jul 2026. `financial_info.html` — annual statements FY2023–FY2025 (million KRW).
- **EVE figures:** "Revenue by Core IP" chart (Black Desert vs EVE, billion KRW, 5 trailing quarters per release). In the 2Q23–3Q25 PDFs the numbers are in the text layer. 4Q25 is image-only and has to be read visually.
- **Ownership change:** Pearl Abyss sold CCP Games to CCP's management on 2026-05-01, and CCP renamed itself Fenris Creations on 2026-05-06. The 2026 reports no longer include EVE, so the Pearl Abyss EVE revenue series ends at 4Q25.

### CCP ehf. annual accounts — `ccp/` (downloaded from Skatturinn, free, 2026-09-28)
- **Publisher:** CCP ehf. (kennitala 450697-3469, now Fenris Creations hf.), filed with Skatturinn. Real, audited. English, **USD**, 62–70 pages, text layer present.
- **Files:** `4506973469_CCP_ehf._ars_{2022,2023,2024,2025}.pdf`. Each report also includes the prior year for comparison.
- **Headline:** revenue $68.6M (2022), $73.2M (2023), $70.4M (2024), $70.3M (2025). Net result −$0.2M, +$5.6M, −$2.9M, −$14.0M.
- **Note 4, revenue by type (2025 / 2024):** subscriptions and in-game sales $60.83M / $55.02M; royalties and licences $4.07M / $5.10M; goods $0.38M / $0.07M; services to a related party $5.00M / $10.19M.
- **Note 4.1, external revenue by region (2025 / 2024):** North America $36.57M / $31.33M; Europe $18.79M / $16.96M; Asia $7.42M / $9.26M; other regions $2.50M / $2.64M.
- **Note 17, deferred revenue (31 Dec 2025 / 2024):** subscriptions $5.31M / $3.47M; in-game purchases not yet consumed $6.57M / $5.44M.
- **Accounting policy:** Omega subscriptions are sold as 1, 3, 6, 12 or 24 months, paid upfront and recognised straight-line over the period. PLEX (in-game currency) revenue is recognised when used. These rules can define the Plan and Subscription entities.

## 9. Static game data (SDE) — `data/raw/sde/eve-online-static-data-latest-jsonl.zip`
- **Publisher:** CCP Games, mirrored by EVE Ref. Real, official reference data. Build 3569502, released 2026-10-02.
- **Files used:** `types.jsonl` (`_key` = type_id, `name` per language, `groupID`), `groups.jsonl` (`_key`, `name`, `categoryID`), `categories.jsonl` (`_key`, `name`), `mapRegions.jsonl`, `mapConstellations.jsonl`, `mapSolarSystems.jsonl`.
- **Example:** type 587 = Rifter → group 25 (Frigate) → category Ship. Type 44992 = PLEX.

## 10. Public contracts — `data/raw/public_contracts/YYYY/public-contracts-YYYY-MM-DD_00-00-*.v2.tar.bz2`
- **Publisher:** CCP ESI, archived by EVE Ref every 30 min. We keep the first snapshot of each day. Real, public.
- **Volume:** 971 daily snapshots, 5.5 GB. No snapshot exists for 2024-11-22, 2024-11-23 and 2025-05-19.
- **Grain:** each snapshot lists every open public contract. One snapshot ≈ 45,600 contracts from ≈ 8,400 issuers (97% item exchange, then auction and courier).
- **Files per snapshot:** `contracts.csv` (`contract_id`, `issuer_id`, `issuer_corporation_id`, `date_issued`, `date_expired`, `type`, `price`, `reward`, `collateral`, `volume`, `region_id`, `system_id`, `station_id`, …), `contract_items.csv`, `contract_bids.csv`.
- **Use:** `issuer_id` + `date_issued` = non-combat activity (traders, haulers). The same contract appears in many snapshots: deduplicate on `contract_id`.
- **Gap:** a contract issued and accepted between two snapshots (under a day) is never seen.

## 11. Character ID month boundaries — `data/raw/character_id_boundaries/`
- **Publisher:** CCP Games, ESI API. Real, official. Built by binary search: `download.py character_id_boundaries`.
- **Method:** character IDs are allocated in order (no backwards dates among 90,594 IDs ≥ 2.1B), and every ID is a character (13% of sampled IDs return 404, the same as the deleted-character rate in the killmails). So **signups in a month = next month's first ID − this month's first ID**, including characters nobody has seen and characters deleted since.
- **Files:** `boundaries.csv` (`month_start`, `first_character_id`, `first_character_birthday`), `probes.jsonl` (every ESI lookup the search made: `character_id`, `birthday` or null, `retrieved_at`).
- **Caveat:** counts characters, not accounts (one account can hold up to three characters).

## 12. Players online — `data/raw/players_online/tranquility_YYYY-MM.jsonp`
- **Publisher:** EVE-Offline (eve-offline.net), a long-running third-party tracker that polls CCP's server status. Real.
- **Volume:** 32 monthly files, Jan 2024 → Aug 2026, one point every 30 minutes (~1,488 per month).
- **Format:** JSONP: `([[unix_ms, players], ...]);`. Strip the wrapper, then parse as JSON.
- **Meaning:** concurrent players logged in at that moment, all activities (miners and market traders included). Not unique players.
- **Examples:** monthly average ≈ 21,600–26,800, peak ≈ 31,000–38,800.
- **Use:** the all-player benchmark for engagement: compare it with the characters active in killmails and contracts.

## 13. Exchange rates — `data/raw/fx/{DEXKOUS,DEXUSEU}.csv`
- **Publisher:** Federal Reserve Bank of St. Louis (FRED). Real, official statistics. Daily, 1981 → 2026-09-25.
- **Columns:** `observation_date`, value. `DEXKOUS` = KRW per USD (1,356.51 on 2026-09-25), `DEXUSEU` = USD per EUR (1.14). Blank values on US holidays.
- **Use:** convert Pearl Abyss's KRW figures to USD so they compare with CCP's accounts.

## 14. Steam players — `data/raw/steam_players/steamcharts_8500.html`
- **Publisher:** SteamCharts, built from the Steam Web API. Real, third-party tracker.
- **Grain:** one row per month since Aug 2012 (86 months): average players, gain, % gain, peak players (HTML table).
- **Use:** Steam share of all players online (≈ 4,000 of ≈ 23,500 in Aug 2026, ≈ 17%): an acquisition-channel proxy.

## 15. All CCP news — `data/raw/news_all/page_NNN.json`
- **Publisher:** CCP Games (Contentful CMS behind eveonline.com). Real, official.
- **Volume:** 685 articles, 2023-01-03 → 2026-10-02: 622 news, 44 dev blogs, 19 patch notes. Same fields as section 7.
- **Use:** the `game_event` timeline (expansion launches, patches, sales). Includes the Viridian, Havoc and Equinox expansion articles.

## 16. Wars — `data/raw/wars/YYYY/wars-YYYY-MM-DD_*.tar.bz2`
- **Publisher:** CCP ESI, archived daily by EVE Ref. Real, public.
- **Volume:** 962 daily snapshots (every day EVE Ref has in the window).
- **Grain:** one JSON per war (`wars/<war_id>.json`): `war_id`, `aggressor` / `defender` (`corporation_id` or `alliance_id`, `isk_destroyed`, `ships_killed`), `allies`, `declared`, `started`, `finished` (when over), `mutual`, `open_for_allies`.
- **Joins:** `killmail.war_id` → `war_id`.

## 17. Sovereignty campaigns — `data/raw/sovereignty_campaigns/YYYY/sovereignty-campaigns-*.json.bz2`
- **Publisher:** CCP ESI, archived hourly by EVE Ref. Real, public.
- **Grain:** each snapshot lists the territory fights under way: `campaign_id`, `event_type` (e.g. `tcu_defense`), `solar_system_id`, `constellation_id`, `defender_id`, `structure_id`, `start_time`, `attackers_score`, `defender_score`.
- **Use:** big territorial conflicts by date and system. Deduplicate on `campaign_id`.

## 18. Forums — `data/raw/forums/{search,topics}/`
- **Publisher:** CCP Games, official forums (forums.eveonline.com, Discourse JSON). Real, public user posts.
- **Queries:** omega price, plex price, subscription, pearl abyss, fenris, new player, unsubscribed (topics active Jan 2024 → Aug 2026). The searches matched 1,396 threads; only the **340 with an on-topic title** are downloaded (`FORUM_TITLE_FILTER` in `download.py`), because searches also match off-topic threads through a single post.
- **Volume:** 476 threads on disk (the 340 on-topic ones plus 136 off-topic ones fetched before the filter; skip them when loading), 2,379 pages, 42,334 posts, 170 MB.
- **Files:** `search/<query>_page_NN.json` (matching topics), `topics/<topic_id>_page_NNN.json` (20 posts per page: `posts[].cooked` HTML, `created_at`, `username`).
- **Use:** satisfaction beyond Steam (sentiment around price changes and the sale). Usernames are public forum names; keep them out of the dashboard.

## 19. Benchmarks — `data/raw/benchmarks/`
- **Papers:** Lee et al. 2011 (WoWAH dataset), Khan 2020 (churn in WoW), Borbora et al. 2011 (EverQuest II churn), Lee et al. 2019 (AION promotion events and retention).
- **Dataset:** `wowah_full.parquet` (319 MB): World of Warcraft Avatar History, 91,065 avatars observed every 10 minutes, 2006–2009 (Parquet copy linked from calmcode.io).
- **Use:** sanity-check our retention and churn figures against published MMO figures.

## 20. Google Trends — `data/raw/google_trends/` (manual export)
- **Publisher:** Google. Relative interest index 0–100, not search counts.
- **Files:** `eve_online_worldwide_weekly.csv` (weekly, 2023-12-31 → 2026-10-04), `eve_online_by_country.csv` (≈ 250 countries; Iceland = 100, then Estonia, Latvia, Russia). The first two lines are a header note; the table starts on line 3.
- **Caveat:** the country index is scaled by each country's total searches, so small countries rank high.

## 21. Twitch viewership — `data/raw/twitch/`
- **Publisher:** SullyGnome, built from the Twitch API. Real, third-party tracker.
- **Monthly pages:** `sullygnome_YYYY-MM.html`, all 32 months Jan 2024 → Aug 2026: hours watched, hours streamed, average and peak viewers, average channels, streamers. Saved by hand in a browser (the archive pages sit behind a Cloudflare browser check, which we don't work around); `download.py twitch` logs them in `sources.csv`.
- **Rolling year:** `sullygnome_365d_to_YYYY-MM-DD.html` (scripted): 2025-10-05 → 2026-10-04 totals.
- **Examples:** hours watched 515.6K (Jan 2024) → 1.5M (May 2024); peaks of 20.4K (May 2025) and 19.3K (May 2026).
- **Use:** interest and marketing signal next to signups, Google Trends and Steam players.

## 22. Patch and release history — `data/raw/patch_history/`
- `patch_notes_page_NN.json`: CCP's **major-version patch notes**, all 244 since 2003 (Contentful, same fields as section 7). Recent years have ~4 a year; minor patches are not in this archive.
- `sde_builds_YYYY.json`: EVE Ref indexes of every static-data build, Oct 2016 → 2026 (379 files: `name` with build number, `last_modified`). Each build ≈ one game deployment.
- `eveuni_expansions.html`: EVE University wiki list of expansions and major releases by year, 2003 → 2025 (176 dated entries). Community-maintained, CC BY-SA.
- **Use:** the `game_event` table: expansions, major patches and deployments by date. Cross-check with section 15 (news).

## 23. Down the Rabbit Hole transcript — `data/raw/qualitative/down_the_rabbit_hole_BCSeISYcoyI.json` (not in git)
- **Source:** "EVE Online | Down the Rabbit Hole", Fredrik Knudsen, https://www.youtube.com/watch?v=BCSeISYcoyI. Fetched with `youtube-transcript-api`. Secondary source: a player documentary; the author says it may contain errors.
- **Format:** 7,973 lines (`start` seconds, `duration`, `text`), 5.9 hours, 1997 → ~2022.
- **Licence:** someone else's work. Kept out of git; cite it, don't redistribute it.
- **Derived:** `data/reference/lore_events.csv` (committed): 40 dated lore events (founding, PLEX, Monoclegate, big battles, casino ban, Pearl Abyss acquisition, Prospector Pack) with the video timestamp for each. Verify against primary sources before quoting a figure.

## How the sources join
- `killmail.victim/attackers.character_id` → `characters.character_id` (Customer)
- `contracts.issuer_id` → `characters.character_id` (non-combat activity)
- `killmail` / `contract_items` type ids → SDE `types._key` (item names, ship classes)
- `killmail.solar_system_id` → MER `static_solarsystems`
- `killmail` ship/item type ids ↔ `market_history.type_id` ↔ MER `static_type_values`
- MER daily CSVs ↔ market history (PLEX) ↔ killmail counts on **date**
- Steam reviews ↔ everything else only on **date** (no player key)
- Pricing and financials ↔ everything else on **date / quarter**

## Known gaps (the ERD boundary)
- No per-player payment or subscription records exist publicly. Monetization is company-level (MER, PLEX market, financials).
- Killmails capture only players who fight, and contracts only those who trade or haul by contract, so retention measured from them is a lower bound (miners and market-only traders stay invisible).
- Customer creation date is missing for ~77% of character records in the dump. For the 838,881 characters in the killmails, the dump plus ESI cover 97.8%; 18,187 (deleted characters) remain unknown.
