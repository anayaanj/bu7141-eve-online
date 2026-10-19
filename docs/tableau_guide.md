# Tableau build guide

How to build the dashboard for `docs/story.md` in Tableau Public, one story point per act, in an EVE Online look.

**Visual reference:** the interactive prototype, `prototype/index.html` (open it from a local web server, for example `cd prototype && python3 -m http.server`; it is also published at https://claude.ai/artifact/7ERYA6wEi2T7TnYkzE2Xsd). Build to match it.

## Setup (once)
1. **Palette:** copy `tableau/Preferences.tps` into `~/Documents/My Tableau Repository/` (replace the empty default), then restart Tableau. You get *EVE story* (five role colours), *EVE alliances* (the ten largest alliances on the map) and *EVE heat* (one-hue ramp for magnitude). The first two role palettes were checked for colour-blind separation on the dark background; ten map colours cannot all be, so the map is read as movement, not as a lookup.
2. **Open** `tableau/eve_story.twb`. Every file in `data/exports/` is connected as an extract (`tableau/extracts/`), which Tableau Public needs before it can save.
3. **After changing the data:** rerun `./scripts/export.sh`, then `python3 scripts/make_workbook.py` (needs `python3 -m pip install tableauhyperapi`), then reopen the workbook. The files added for this version of the story (`great_wars`, `signup_dots`, `acquisition_cost_by_year`, `largest_battles`, `famous_battles`, `alliance_players`, `active_by_character_age`, the veterans and dollars-destroyed rows in `eve_at_a_glance`) have CSVs in `data/exports/` but no extract yet until that script is rerun.
4. **Saving:** Tableau Public saves to your public profile. Use *File > Save to Tableau Public*; you can hide the workbook on your profile while it's a draft.

## The EVE look
| Element | Setting |
|---|---|
| Dashboard and sheet background | `#070b10` (Format > Shading > Worksheet and Pane) |
| Panels (containers) | `#0d141c`, 1 px border `#1f3344` |
| Text | `#d7e2ec`; muted labels `#8195a8` |
| Titles and UI accent | `#4fd1ff` (text only) |
| Group, win; Goonswarm | `#00a3c9` |
| Alone, starter corporation; other alliances | `#5b6b7a` |
| Death by a player; Pandemic Horde | `#d25030` |
| Death by the computer; Fraternity | `#8b5dce` |
| Alliances on the map | *EVE alliances* palette in `tableau/Preferences.tps` for the ten largest (rank order); the rest cycle through Tableau's automatic colours |
| Money (single-series charts only) | `#b08505` |
| Gridlines and axes | none, or `#1f3344` at 50% |
| Fonts | Tableau Public renders in the browser, so use *Tableau Book* / *Tableau Bold*. Titles in capitals, letter-spaced, in the accent colour. |
| Estimates | dotted borders or 50% opacity, with an "estimate" label |
| Rules | Never two different y-scales on one chart (use two stacked charts with a shared x axis, or a table). Colour follows the entity, not its rank. Values and labels in text colours, not series colours. Every panel title ends with its base in the accent colour: "of 100 who sign up", "of 100 we can see", "one-day newcomers", "per engaged newcomer, 2025". |

Set it once: *Format > Workbook* (fonts, colours), then *Format > Shading* on each sheet. Dashboard size: **1366 × 768** (fixed), one dashboard per act, combined in a **Story** (*Story > New Story*), with the story point captions written as the finding. Each dashboard ends with a one-line text box in italics: the handoff question from `docs/story.md`.

**Tiles** are one text sheet per number: the big number in Tableau Bold, the label in muted text. Tiles on act 4 get dotted borders (estimates).

## Act 1: What is EVE?
**Headline:** *One world for 23 years. Of 100 who sign up, one is still playing a year later.* Layout: left column = players by year over the funnel; right = the zones map; a row of four small cards (alliances, battles, who plays, money) below.

**⭐ Players online, by year** (`players_history_monthly`): filter `series = players_online`. Columns `YEAR(month)` (discrete), Rows `AVG(value)`, mark **Bar**. Colour by a calculated field: `IF YEAR([month]) >= 2024 THEN 'story' ELSEIF YEAR([month]) = 2013 THEN 'peak' ELSE 'other' END` (story `#4fd1ff`, peak `#00a3c9`, other `#00a3c9` at 50% opacity). Fixed y axis 0–36,000, labels `20K`. Annotate the 2013 bar "peak · 32,720" and the 2026 bar "this story's data · 25,046".

**⭐ Most of it has no police** (`map_layers`): Map Layers as in the old recipe (`lon = [map_x] / 1e15`, `lat = [map_y] / 1e15`, `MAKEPOINT`, background map None). Layer **Links** (`layer = link`, Line, Path `point_order`, `#1f3344`) and layer **Systems** (`layer = system`, Circle, Colour by a calc on `security_band`: High Sec `#4fd1ff`, Low Sec `#e3b53b`, Null Sec (NPC) and Null Sec (Sov) `#d25030`, everything else `#2a3540`). Beside it a bar sheet: Rows the same band calc (High-sec, Low-sec, Null-sec), Columns `COUNTD(solar_system_id)`, same colours, label at the bar end as "1,246 systems".

**Largest alliances** (`alliance_players`): Rows `alliance_name` sorted by `rank`, Columns `players`, mark Bar, colour by `kind` (Goonswarm `#00a3c9`, Fraternity `#8b5dce`, Pandemic Horde `#d25030` via the *EVE alliances* palette; other `#4a5866`), labels `54,021`. Alias the names to Goonswarm · Fraternity · Pandemic Horde · Other. Caption: "Other: The Initiative, Dracarys, Brave, TEST, Northern Coalition and Pandemic Legion."

**⭐ Costliest battles ever** (`famous_battles`): Rows `battle` sorted by `usd_estimate` descending, Columns two calculated fields on a stacked bar: `[usd_estimate] * [side_a_share]` (Goonswarm's side, `#00a3c9`) and `[usd_estimate] * (1 - [side_a_share])` (the other side: M2-XFE `#d25030`, B-R5RB `#8195a8`, Atioth `#8b5dce`), *Measure Names* on Colour, labels `$378K`. Tooltip `side_a`, `side_b`, `players`, `isk_lost`, `split_basis`. Dashed panel border: estimates.

**Who plays today** (`active_by_character_age`): one bar, Columns `SUM(share)`, Colour `age` sorted by `sort` (10+ years `#006b85`, 3–10 `#0088a8`, 1–3 `#33b8d6`, under a year `#8195a8`), *Percent of total* labels. Two text tiles: `kind = Veteran` → "80% veterans · a year or more in the game · 60% flew Omega in August" (weighted by `characters`); `kind = Newcomer` → "20% under a year · in their first year · 32%".

**⭐ Of 100 who sign up** (`signup_dots` + `kpi_tiles`): three dot rows on one sheet. Build a small scaffold in the data pane or use `signup_dots` three times: row 1 all 100 cells (`#5b7f93`), row 2 the 13 cells whose `kind` is not "Never seen…" (`#a8bccb`), row 3 the one "Still playing a year later" cell (`#4fd1ff`); Columns `x`, Rows a `step` field then `y`, mark **Circle**, no headers or gridlines. Beside each row a text tile from `kpi_tiles`: `New characters created` (2,733,207) · `New players who engaged` (356,769, "13% ever seen fighting or trading") · "1 in 100 still playing a year later" (`Still active after 12 months (all new players)` = 8.2% of those seen). Closing text box in the accent colour: "Only one in a hundred is still playing a year later". This is the same base as act 2's 100 dots.

**How real money enters the game** (`plex_monthly`): two text tiles. `$1 ≈ 105M ISK`: AVG(`plex_avg_price_isk`) ÷ (24.99 ÷ 500). `$20 or 2.6B ISK`: 500 × AVG(`plex_avg_price_isk`). Caption: $20 buys a month of Omega; $25 buys 500 PLEX, an item worth that month, which players sell for ISK.

**Handoff text box:** "Why aren't new players staying?"

## Act 2: Newcomers arrive alone, and leave
**Headline:** *Of 100 newcomers, 99 are gone within a year. Most leave after one day, alone.*

Layout: three square charts across the top (dots, waffle, staircase), the death map wide below with a 2 × 2 tile block beside it.

**⭐ 100 sign up · of 100 who sign up** (`signup_dots`): Columns `x` (dimension), Rows `y` (dimension), mark **Circle**, size large, *Colour* `kind`: **87** "never seen fighting or trading with another player" (`#26323d`), **12** "seen, then gone within the year" (`#5b6b7a`), **1** "still playing a year later" (`#4fd1ff`, the last cell, bottom right). No gridlines, legend as three counts. Footnote: "New characters, Jan 2024 – Aug 2026: 13 in 100 are ever seen fighting or trading with another player; 8.2% of those are still playing a year later. CCP's own figure (2019): 9 in 10 new players quit in their first week."

**⭐ Their first month · of 100 we can see** (`waffle_first_day`): Columns `x`, Rows `y`, mark **Square**, *Colour* `category` (killed by a player `#d25030`, by the computer `#8b5dce`, other `#3a4652`, seen on 2+ days `#00a3c9`), size maximum, no gridlines. Footnote: "The 13 we can see, scaled to 100."

**Seen on more days, seen again later · of 100 we can see** (`first_month_active_days`): Columns `days_seen_first_month`, Rows `retention_month_3`, mark **Bar**, the 1-day bar in `#5b6b7a` and the rest in `#00a3c9`. Annotate 9.5% at 1 day and 45% at 8+. Footnote: "62% are seen on a single day; 9.5% of them are seen again 3 months later, against 45% of those seen on 8+ days."

**⭐ Where the one-day newcomers die** (`map_layers` related to `casual_deaths_by_system`): same dual-axis map as act 1; systems sized and coloured by `casual_newcomers_killed` (palette *EVE heat*), starter systems (`is_starter_system`) as a white ring. Annotate the five hotspots: Ahbazon, Tama, Jita, Uitra, Ami. Footnote: "Safe at home: 0.15% die in a starter system (white rings). They die after heading out alone; about 1 in 6 in just five systems. The official tutorial and career missions are solo, against the computer."

**Tiles (2 × 2):** **1 in 100** "signups are still playing a year later" (`kpi_tiles`: share who engage × still active after 12 months) · **62%** "of the newcomers we can see appear on a single day in their first month" (`first_month_active_days`, `share` at 1 day) · **0.15%** "of one-day newcomers killed by a player died in a starter system; 34% died within a week of creating their character" (`casual_first_day`, dimensions "Killed by a player in a starter system" = Yes and "Killed in their first week" = Yes) · **37%** "of one-day newcomers were still in the starter corporation: no group had taken them in" (`casual_first_day`, "Their corporation" = NPC starter corp).

**Handoff text box:** "The few who return: what did they have that the others didn't?"

## Act 3: The ones who stay found a group
**Headline:** *Newcomers in a group come back twice as often.*

**Tiles (four across the top):** **2×** "as many one-day newcomers come back at month 3 in a player corporation, in player-held space or after a win (2.0–2.3× across the three pairs)" (`come_back_pairs`) · **1.5–1.6×** "even among newcomers equally active in their first month: being in a corporation still helps" (`robustness_equal_activity`) · **414 → 0** "systems held by Pandemic Horde, Nov 2025 to Apr 2026: the group that took in the most newcomers lost its space" (`horde_story`) · **8% vs 22%** "of newcomers who joined Horde in November 2025 were still playing at month 3, against other alliances' newcomers" (`horde_story`, November 2025 row).

**⭐ Dumbbell · one-day newcomers, alone vs together** (`come_back_pairs`): Rows `pair`; Columns `alone_retention_month_3` and `together_retention_month_3` on a synchronised dual axis (one scale, 0–20%). First mark **Circle** (`#5b6b7a`), second **Circle** (`#00a3c9`); add a **Line** between them with *Measure Values* and *Path*. Label both ends with the value and the group name.

**Is it just that keen players join groups? · all newcomers we can see** (`robustness_equal_activity`): grouped bars, `first_month_active_days` on Columns, `retention_month_3_any_activity` on Rows, *Colour* `corp` (In a corp `#00a3c9`, No corp `#5b6b7a`), one axis 0–40%. Footnote: "Even among players equally active in their first month, those in a corporation come back more often. A link, not proof."

**⭐ Pandemic Horde** (`horde_story`): two charts stacked on one sheet, sharing `month` on Columns. Top: `horde_systems` (mark **Area**, `#d25030` at 40%), "Systems Horde holds". Bottom: `horde_retention_month_3` and `other_alliances_retention_month_3` (*Measure Names* on Colour, mark **Line**: Horde `#d25030`, other alliances `#5b6b7a`), "Newcomers still playing at month 3". Annotate November 2025: "Horde loses its space; joined Nov 2025: 8% vs 22%".

**Handoff text box:** "Keeping a newcomer means grouping them. What does buying one cost, and what does keeping one pay?"

## Act 4: Buying newcomers costs more every year; keeping them pays
**Headline:** *A signup now costs $16. Only grouped newcomers pay back their cost.* Every panel and tile on this page is dotted (estimate).

**Tiles (four across the top):** **$16.25** "of marketing per signup in 2025, up from $10.43 in 2024 (CCP's accounts ÷ characters created)" (`unit_economics`, `cac_per_signup`) · **$117** "per newcomer who engages: 2025 marketing ÷ newcomers seen fighting or trading" (`cac_per_engaged_newcomer`) · **$409** "of first-year revenue not earned for each newcomer who leaves instead of staying the year" (`arpu_month` × 12 = $511, minus `newcomer_value` "All new players" `ltv_first_year` $102) · **$56.1M a year** "not earned from 2025's 137,000 engaged newcomers: what they would have paid had all stayed the year, less what they did (a ceiling; EVE's revenue was $60.8M)" (`engaged` × $409).

**⭐ What buying a newcomer costs · CCP, by year** (`acquisition_cost_by_year`): a text table, Rows `measure` (in file order), Columns `year`, text `value` formatted per row (dollars in millions for marketing, counts for signups and engaged, `$0.00` for the two cost-per rows), a last column `change_vs_prior` as a percentage (positive in `#b08505`, negative in `#d25030`). Shade the two "Cost per" rows. This replaces the old two-axis "spend up, signups down" chart. Footnote: "Marketing from CCP's audited accounts (all of CCP, not only new EVE players). Signups are characters created; engaged means seen fighting or trading."

**⭐ Revenue in year one vs the marketing it took · per engaged newcomer, 2025** (`unit_economics` 2025 row + `newcomer_value` "All new players"): two horizontal bars on one dollar axis fixed 0–560: "The average newcomer" $102 (`ltv_first_year`, sub-label "2.4 active months", `#5b6b7a` because it falls short) and "A player who stays the year" $511 (`arpu_month` × 12, sub-label "12 months", `#00a3c9`). A dashed vertical reference line in `#b08505` at $117 (`cac_per_engaged_newcomer`) labelled "$117 of marketing to bring one in". Big dollar labels at the bar ends. Footnote: "$43 per active player a month × months active. Upper bounds: all revenue is put on visible players."

**⭐ Who pays back their cost · first-year value ÷ $117** (`newcomer_value`): Rows `segment` (sorted by `ltv_to_cac`, five rows: starter corporation 0.6×, no corp no kill 0.7×, one-day mid-sized corp 0.9×, average 0.9×, corp and a kill 1.1×), Columns `ltv_to_cac`, mark **Bar**; reference line at **1.0** labelled "pays back its cost". Bars below 1 in `#5b6b7a`, above in `#00a3c9`. Footnote: "Same money, split by what the newcomer did in their first month. Starter-corporation and mid-sized-corporation rows are one-day newcomers; the others are all newcomers we can see."

**Handoff text box:** "If grouping doubles return and pays back the spend, how much is it worth, and how would we know it works?"

## Act 5: Group them in week one, then test it
**Headline:** *Put newcomers in a group in week one. Then test it.*

**Tiles (three across the top):** **44,452** "engaged newcomers a year play alone: no corporation, no win in their first month (2025)" (`whatif_inputs`, first row `newcomers_per_year`) · **+$47** "more first-year revenue from each of them if they had found a group and a win instead (estimate, 2025 ARPU)" (`value_in_group` − `value_alone`) · **+13% signups** "a month since the sale of CCP to its management (May 2026), while active players moved −4%: more people are trying EVE; will the new owners get them through week one?" (`sale_before_after`, after ÷ before − 1 for `signups_per_month` and `active_characters_per_month`).

**⭐ What-if slider** (`whatif_inputs`)
1. Create a parameter **Share moved into a group**: float, range 0 to 0.5, step 0.05, display as %.
2. Calculated field **Extra first-year revenue** = `[Share moved into a group] * SUM([newcomers_per_year]) * (SUM([value_in_group]) - SUM([value_alone]))`.
3. Text sheet showing it in big numbers; a `scenario` filter as two radio buttons (default the first row); show the parameter control as a slider. At 10% the first scenario reads about $0.21M (4,445 newcomers × $47).
4. Caption: "First year only; a test would measure it for real."

**What to do** (text box): end the tutorial in the corporation finder, not in solo missions; a first fight they can win, with a group; spend on keeping as well as buying (a newcomer in a group pays back their cost in year one; one alone covers about 60%). **A/B test:** half of new players end the tutorial in the corporation finder, half in today's solo missions; measure month-3 return and first-year revenue.

**Caveats** (text box across the bottom of this page, no separate caveats story point): the five bullets from `docs/story.md`.

## Story assembly
- Five story points, one per act, caption = the headline above.
- Same colour language everywhere: grey = alone, cyan = group or win, coral = death, violet = killed by the computer, gold = money.
- Event markers (`events`) as reference lines on every time chart.
- Not used on any page (extracts can stay, nothing to build): `largest_battles`, `sovereignty_monthly`, `war_zones_monthly`, `revenue_quarterly`, `funnel_monthly`, `returners_monthly`, `cohort_heatmap`, `conversion_by_segment`, `isk_monthly`, `plex_monthly`, `omega_prices`, `signals_monthly`, `ccp_annual`, `retention_by_segment`, `robustness_contracts_only`, `dau_mau_monthly`, `horde_collapse`, `map_links`, `map_systems`, `sovereignty_alliances_monthly`.
