# ERD design: normalization and derived data

How we got from the raw files to the ERD in `docs/erd.dbml`, using the method and terms of Connolly, Begg & Holowczak, *Business Database Systems* (Pearson, 2008):

- **Chapter 8, Normalization:** 1NF, 2NF and 3NF (Sections 8.3–8.5).
- **Section 6.3.3 and Step 1.3, Derived attributes:** shown in the model with a `/` prefix.
- **Chapter 11, Step 3.2, Design representation of derived data:** whether each derived column is stored or calculated.
- **Chapter 11, Step 7:** controlled redundancy.

We designed top-down (an ER model first) and then used normalization to check the tables, as the book recommends (Chapter 8 preview). The examples below come from our own raw data (section numbers refer to `docs/raw_inventory.md`).

## 1. First normal form (1NF)

> **1NF:** a table in which the intersection of every column and record contains only one value (Section 8.3).

Most of our raw sources are nested JSON, so they are not in 1NF as delivered. Each repeating group or multi-valued attribute became its own table, or was left out when no KPI needs it.

| Raw source | Not in 1NF because | What we did |
|---|---|---|
| Killmail JSON [1] | `attackers[]` is a repeating group (many attackers per killmail); `victim` is a nested object | One row per participant in **`killmail_participant`** (victim = participant 0, attackers 1..n), keyed `(killmail_id, participant_no)` |
| Killmail JSON [1] | `items[]` (dropped and destroyed items) is another repeating group | Not modelled: no KPI uses it. It would become a `killmail_item` table |
| Forum topic JSON [18] | `posts[]` holds many posts per topic | **`forum_post`**, one row per post, with `topic_id` as a foreign key |
| Character dump [2] | `history[]` (corporation history) is a repeating group | Not modelled: membership over time comes from `killmail_participant.corporation_id` instead |
| SDE types [9] | `name` holds one value per language (`{"en": …, "de": …}`) | Kept the English name only: one value per column |
| Wars [16] | `allies[]` is a repeating group; `aggressor` and `defender` are nested objects | Nested objects flattened into single-valued columns (`aggressor_alliance_id`, …). Allies not modelled |
| Steam reviews [5] | `author` is a nested object | Flattened: only `steam_author_id` and the per-review `playtime_at_review` are kept (see 3NF) |
| Monthly Economic Report [4] | One zip holds many tables | Each CSV becomes rows of a single-valued table (`economy_daily`) |

## 2. Second normal form (2NF)

> **2NF:** a table in 1NF in which the values in each non-primary-key column are determined by the values in **all** the columns that make up the primary key (Section 8.4). Only tables with a composite primary key can break it, through a **partial dependency**.

Flattening the raw data to 1NF produced composite keys, and with them partial dependencies. We removed each one by moving the dependent columns into their own table, keeping a copy of the key part as a foreign key, exactly as in the book's `TempStaffAllocation` example (Figure 8.6).

| 1NF table after flattening | Partial dependency | Resolution |
|---|---|---|
| Participant rows `(killmail_id, participant_no, killmail_time, solar_system_id, character_id, ship_type_id, …)` | `killmail_id → killmail_time, solar_system_id, war_id` (only part of the key) | Moved to **`killmail`**. `killmail_participant` keeps only participant-level columns |
| Contract snapshot rows `(snapshot_date, contract_id, issuer_id, price, type, …)` [10] | `contract_id → issuer_id, price, type, date_issued` (the same contract repeats in every daily snapshot) | **`contract`** keyed by `contract_id`. Snapshot dates collapse into `first_seen` / `last_seen` |
| Campaign snapshot rows `(snapshot_time, campaign_id, solar_system_id, event_type, scores)` [17] | `campaign_id → solar_system_id, event_type, start_time` | **`sov_campaign`** keyed by `campaign_id` |
| Forum rows `(topic_id, post_id, title, post_text, …)` [18] | `topic_id → title, posts_count` | **`forum_topic`** and **`forum_post`** |
| Market rows `(date, region_id, type_id, region_name, type_name, prices)` [3] | `region_id → region_name`; `type_id → type_name` | Names live in **`region`** and **`item_type`**. `market_history_daily` keeps only the prices and volumes that depend on the full key |
| Price rows `(plan_id, effective_date, currency, plan_name, billing_cycle_months, list_price)` [6][7] | `plan_id → plan_name, billing_cycle_months` | **`plan`** and **`plan_price`** |

The remaining composite-key tables (`character_month_activity`, `fx_rate`, `economy_daily`, `interest_metric`) have no partial dependency: every non-key column depends on the whole key. Every other table has a single-column primary key, so it is automatically in 2NF.

## 3. Third normal form (3NF)

> **3NF:** a table in 1NF and 2NF in which the values in all non-primary-key columns can be determined from **only** the primary key (or another candidate key) and no other columns (Section 8.5). It forbids **transitive dependencies** (a → b → c).

| Raw structure | Transitive dependency | Resolution |
|---|---|---|
| MER `static_solarsystems` [4]: `solarsystem_id, region_id, region_name` | `solar_system_id → region_id → region_name` | **`region`** table |
| SDE `mapSolarSystems` [9]: system, constellation and region IDs | `solar_system_id → constellation_id → region_id` | `solar_system` keeps only `constellation_id`; region comes through **`constellation`** |
| SDE types and groups [9] | `type_id → group_id → group_name, category_id → category_name` | **`item_type` → `item_group` → `item_category`** |
| Character dump [2]: character with `corporation_id` and `alliance_id` | `character_id → corporation_id → alliance_id` (a character's alliance is its corporation's alliance) | `player_character` keeps only `corporation_id`; the alliance comes through **`corporation`** |
| Steam review `author` [5]: `num_games_owned`, `num_reviews`, `playtime_forever` | `recommendation_id → steam_author_id → num_games_owned, …` | Author attributes dropped (no KPI needs them), so no `steam_author` table. Only per-review facts stay |
| Financial figures [8] | Publisher details would depend on the document, not the figure | `financial_metric` holds the figure and a `source_id`; publisher, URL and retrieval date live in **`source_document`** |

**Checked and kept on purpose (not violations):**

- **`killmail_participant.corporation_id` and `alliance_id`.** These record the corporation and alliance *at the time of the kill*. `corporation.alliance_id` is today's alliance, and corporations change alliance over time, so `corporation_id → alliance_id` does not hold across the history. Both are facts of the event, determined by the key.
- **`financial_metric.currency`.** In our data CCP reports in USD and Pearl Abyss in KRW, but that is a property of these reports, not a rule: an entity can report figures in more than one currency, so `entity → currency` is not a dependency we enforce.
- **`contract.region_id` with `solar_system_id`.** `solar_system_id → region_id` holds when the system is known, but contracts in player-owned structures have no system (6,840 of 45,558 contracts, 15%, in one snapshot), and then the region is the only location. This is the one deliberate exception; it is listed under controlled redundancy below.

## 4. Derived data

> **Derived attribute:** an attribute whose value is derivable from the value of a related attribute or set of attributes, not necessarily in the same entity (Section 6.3.3). All derived attributes are shown in the model, prefixed with `/` (Step 1.3).

In `docs/erd.dbml` every derived column's note starts with **`/derived:`** followed by its rule. The three fully derived tables (`character_month_activity`, `players_online_daily`, `battle`) also have a grey header in the diagram. The markers carry into the database as column comments (`db/schema.sql`).

### Stored or calculated? (Step 3.2)

The book's rule: store a derived column when calculating it each time costs more than storing it and keeping it consistent. We applied it like this:

- **Stored** when the calculation needs a very large table (`killmail_participant` has ~140M rows), or when the source rows are not kept in the database at all (daily contract snapshots, hourly campaign snapshots, 30-minute player counts).
- **Stored** for date parts used as join keys (`kill_date`, `issued_date`), so they can reference `calendar_date`.
- **Calculated** in queries (not stored) for every KPI: MAU, retention, churn, ARPU, LTV and CAC are computed from the tables at analysis time, and so is the USD value of Pearl Abyss's KRW figures (`financial_metric` joined to `fx_rate`).

Stored derived columns break 3NF on purpose (for example `player_character.cohort_month` depends on `signup_date`, not only on the key). This is the **controlled redundancy** of Step 7. It is safe because the load script computes every derived column from its source in one place, and the database is reloaded rather than edited by hand, so the copies cannot drift apart.

### Register

| Column | Derived from | Stored because |
|---|---|---|
| `calendar_date.month`, `quarter`, `year`, `after_sale` | `date` | Generated once; used in nearly every join and grouping |
| `item_type.alpha_can_fly` | SDE `typeDogma` (required skills) + `cloneGrades` (Alpha limits) | Needs a recursive skill check; used against 140M participant rows |
| `corporation.is_npc` | `corporation_id < 2000000` | Cheap, but stored for readability in the dashboard |
| `player_character.cohort_month` | `signup_date` | Grouping key for every cohort chart (890K characters) |
| `player_character.is_deleted` | Dump flag, ESI 404, Doomheim membership | Combines three sources, one of them not in the database |
| `player_character.inferred_plan`, `first_omega_seen` | `killmail_participant` + `item_type.alpha_can_fly` | Scans 140M rows |
| `character_signup_month.characters_created` | Next month's `first_character_id` | Needs the next row; the count is the main acquisition figure |
| `killmail.kill_date` | `killmail_time` | Join key to `calendar_date` |
| `killmail.attacker_count` | Count of attacker rows in `killmail_participant` | Avoids aggregating 140M rows |
| `killmail.battle_id` | Clustering of killmails by system and hour | Clustering is expensive |
| `contract.issued_date` | `date_issued` | Join key to `calendar_date` |
| `contract.first_seen`, `last_seen` | Daily snapshots | Snapshots are not stored in the database |
| `character_month_activity` (all columns) | `killmail_participant`, `contract`, `item_type`, `corporation` | Monthly roll-up of 140M + 4.7M rows; feeds every retention query |
| `players_online_daily` (all columns) | 30-minute player counts | Raw points are not stored |
| `sov_campaign.first_seen`, `last_seen`, `final_*_score` | Hourly snapshots | Snapshots are not stored |
| `battle` (all columns) | Clustered `killmail` + `killmail_participant` rows | Clustering is expensive |
| `steam_review.created_date`, `playtime_at_review_hours` | Unix timestamp; minutes | Join key; unit conversion |
| `forum_topic.created_date`, `forum_post.created_date` | `created_at` timestamps | Join key to `calendar_date` |
| `forum_post.author_hash` | SHA-256 of the username | Privacy: counts distinct posters without storing names |
| `forum_post.post_text` | Post HTML with tags stripped | Cleaned once for text analysis |
| `contract.region_id` (when `solar_system_id` is known) | `solar_system → constellation → region` | Structure contracts have no system; see 3NF exceptions |
