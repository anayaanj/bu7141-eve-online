# Tableau build guide

How to build the dashboard for `docs/story.md` in Tableau Public, one story point per act, in an EVE Online look.

**Visual reference:** the interactive prototype (private artifact, ask Jose for access) shows every view below in the target look; build to match it.

## Setup (once)
1. **Palette:** copy `tableau/Preferences.tps` into `~/Documents/My Tableau Repository/` (replace the empty default), then restart Tableau. You get *EVE story* (five role colours), *EVE alliances* (the ten largest alliances on the map) and *EVE heat* (one-hue ramp for magnitude). The first two role palettes were checked for colour-blind separation on the dark background; ten map colours cannot all be, so the map is read as movement, not as a lookup.
2. **Open** `tableau/eve_story.twb`. Every file in `data/exports/` is already connected as an extract (`tableau/extracts/`), which Tableau Public needs before it can save.
3. **After changing the data:** rerun `./scripts/export.sh`, then `python3 scripts/make_workbook.py` (needs `python3 -m pip install tableauhyperapi`), then reopen the workbook.
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
| Rules | Never two different y-scales on one chart (use two stacked charts with a shared x axis). Colour follows the entity, not its rank. Values and labels in text colours, not series colours. |

Set it once: *Format > Workbook* (fonts, colours), then *Format > Shading* on each sheet. Dashboard size: **1366 × 768** (fixed), one dashboard per act, combined in a **Story** (*Story > New Story*), with the story point captions written as the finding.

## Act 0: What is EVE Online?
**Headline:** *One universe, run by its players. Empires rise and fall.*

**⭐ 20 years of EVE** (`players_history_monthly` + `great_wars`, both filtered to 2006 and later), full width across the top
1. Data source `players_history_monthly`, filter `series = players_online`. Columns `month` (continuous, exact date), Rows `value`. Mark **Area** in `#00a3c9` at 30% opacity with a line on top (dual axis, synchronised, mark Line). Axis from January 2006 to August 2026 (*Edit Axis > Fixed*; there is no player count before June 2006), y axis titled "online"; tick labels as `20K`.
2. Shade 2024–2026: a reference band on the month axis (*Analytics > Reference Band*, from 2024-01-01 to 2026-08-31, fill `#4fd1ff` at 7%), label "This story's data".
3. Subscriber announcements (`series = subscribers`): a second sheet, Columns `month`, mark **Text** with `value` (format `500K`) in `#b08505`, placed as a thin strip directly above the chart with the same fixed axis, or as annotations on the first sheet (*Annotate > Point*) if you prefer one sheet. They are a different count (paying subscribers, not players online), so they never go on the y axis.
4. Turning points (`great_wars`): relate `great_wars.date` to the month axis (*Data > Edit Relationships* on `date = month`, after a calculated `DATETRUNC('month', [date])`), mark **Circle** in `#0d141c` with a 2 px `#4fd1ff` border, on the dual axis at the players-online value (join to `players_history_monthly`). Label four: "A spy disbands an empire" (2009), "TEST: newcomers welcome" (2010), "B-R5RB: $300K of ships" (2014), "Pearl Abyss buys CCP" (2018). Tooltip `what_happened`, `scale`, `source`.

**⭐ Animated territory map with battles** (`map_layers` related to `sovereignty_monthly` and `war_zones_monthly`)
1. Data source `map_layers`: *Data > Edit Relationships*, add `sovereignty_monthly` (relate `solar_system_id = solar_system_id`) and `war_zones_monthly` (same key; it also has `month`).
2. Columns: `map_x` (dimension, continuous). Rows: `map_y` three times. Right-click the second and third `map_y` > *Dual Axis* > *Synchronize Axis* (Tableau allows two axes per row shelf, so put the battle rings on the second axis together with the systems if you run out: use *Shape* instead of a third axis). Reverse the y axis if north looks upside down (*Edit Axis > Reversed*). Hide the axes.
3. Links card: mark type **Line**, filter `layer = link`, *Detail* `link_id`, *Path* `point_order`, colour `#1f3344`, size small.
4. Systems card: mark type **Circle**, filter `layer = system`, *Colour* `highlight` (one colour per alliance, every alliance; sort the colour legend by `rank` and assign the *EVE alliances* palette so the ten largest get the fixed colours and the rest cycle; unclaimed systems stay out of the relationship and show nothing), size very small. Hide the colour legend: the point is to watch control move, not to read every alliance.
5. Battles card: mark type **Circle**, filter `layer = system` and `largest_battle_pilots >= 100`, *Size* `largest_battle_pilots` (fixed range: 100 pilots small, 4,367 the largest), no fill (*Colour > Opacity* 8%) with a 1 px white border (`#ffffff`). One colour only: the alliance colours are already taken and the ring is the signal. Tooltip: system, `largest_battle_pilots`, `battles`, `ships_destroyed`.
6. Drag `month` to **Pages**. Show the history trail off, speed slow (about one second a month). The play button animates 32 months: Pandemic Horde vanishes around December 2025 and Goonswarm spreads; the biggest ring is 4-HWWF in April 2026.
7. Legend: only "○ largest battle in the system that month (100+ pilots), sized by pilots. One colour per alliance."

**Side panel tiles** (`eve_at_a_glance`): one text sheet per number (big number in Tableau Bold, label in muted text): `Years online` (23, since May 2003), `Subscribers at the peak` (500,000, February 2013), `Players online at the same time (average)` (about 24,000, 2024–2026), `Subscription and in-game revenue 2025 (USD)` ($60.8M a year). Fights are on the map, not in the tiles.

## Act 1: The paradox
**Headline:** *EVE loses 99 of every 100 newcomers.*

**Four tiles** (one text sheet each, big number in Tableau Bold, label in muted text), in this order: **1 in 100** "signups are still playing a year later (Jan 2024 – Aug 2026)" (`kpi_tiles`: share who engage × still active after 12 months ≈ 1.1%); **$16.1M** "spent on marketing in 2025, up 41% on 2024 (CCP's accounts)" (`unit_economics`, `marketing`, 2025 vs 2024); **$409** "of first-year revenue lost for each newcomer who leaves instead of staying the year (estimate)" (`unit_economics` 2025: `arpu_month` × 12 = $511, minus `newcomer_value` "All new players" `ltv_first_year` $102); **$56.1M a year** "not earned from 2025's 137,000 engaged newcomers: what they would have paid had all stayed the year, less what they did (ceiling estimate; EVE's revenue was $60.8M)" (`unit_economics` 2025: `engaged` × ($511 − $102); potential $70.0M against actual $13.9M).

**⭐ 100 newcomers sign up** (a 10 × 10 unit chart, on our own numbers so it matches the money panel): a small sheet of 100 rows (`x` 1–10, `y` 1–10, like `waffle_first_day`) with a `kind` of three values: **87** "never seen fighting or trading with another player" (`#26323d`), **12** "seen, then gone within the year" (`#5b6b7a`), **1** "still playing a year later" (`#4fd1ff`, the last cell, bottom right). From `kpi_tiles`: 13% engage, 8.2% of those are active at month 12. Mark **Circle**, size large, no gridlines, legend as three counts. Footnote: "New characters, Jan 2024 – Aug 2026: 13 in 100 are ever seen fighting or trading with another player; 8.2% of those are still playing a year later. CCP's own figure (2019): 9 in 10 new players quit in their first week."

**Bringing in the average new player is not worth the spend · 2025 · estimate** (`unit_economics` 2025 row + `newcomer_value`, segment "All new players"): two horizontal bars of revenue in year one on one dollar axis fixed 0–560 (ticks $0 to $500): "The average newcomer" $102 (`ltv_first_year`, sub-label "2.4 active months", `#5b6b7a` because it falls short) and "A player who stays the year" $511 (`arpu_month` × 12, sub-label "12 months", `#00a3c9`). A dashed vertical reference line in `#b08505` at $117 (`cac_per_engaged_newcomer`) labelled "$117 of marketing to bring one in". Big dollar labels at the bar ends. Dashed card border (estimate). Footnote: "Revenue in year one: $43 per active player a month × months active (the average newcomer who engages is active 2.4 months; a player who stays, 12). Marketing: CCP's 2025 spend ÷ newcomers seen fighting or trading. Upper bounds: all revenue is put on visible players." The base is the 13 who engage, not all 100: the 87 never seen are at zero. Act 4 keeps the split by newcomer group.

## Act 2: A newcomer's first day
**Headline:** *For most newcomers, the only trace they leave is their death.*

**⭐ Waffle** (`waffle_first_day`): Columns `x` (dimension), Rows `y` (dimension), mark **Square**, *Colour* `category` (killed by a player `#d25030`, by the computer `#8b5dce`, other `#3a4652`, seen on 2+ days `#00a3c9`), size maximum, no gridlines. Title: "100 newcomers we can see".

**Staircase** (`first_month_active_days`): Columns `days_seen_first_month`, Rows `retention_month_3`, mark **Line** (step: right-click the line > *Line type: stepped*), label each step. Annotate 9.5% at 1 day and 45% at 8+.

**Where they die** (`map_layers` related to `casual_deaths_by_system`): same dual-axis map as act 0 (both axes share the map coordinates, so this is one scale); systems sized and coloured by `casual_newcomers_killed` (palette *EVE heat*), starter systems (`is_starter_system`) as a white ring. Annotate the five hotspots: Ahbazon, Tama, Jita, Uitra, Ami.

## Act 3: The few who come back
**Headline:** *Newcomers in a group, in player space or with a win come back twice as often.*

**⭐ Dumbbell** (`come_back_pairs`): Rows `pair`; Columns `alone_retention_month_3` and `together_retention_month_3` on a synchronised dual axis (one scale). First mark **Circle** (`#5b6b7a`), second **Circle** (`#00a3c9`); add a **Line** between them with *Measure Values* and *Path*. Label both ends.

**⭐ Pandemic Horde** (`horde_story`): two charts stacked on one sheet, sharing `month` on Columns. Top: `horde_systems` (mark **Area**, `#d25030` at 40%), "Systems Horde holds". Bottom: `horde_retention_month_3` and `other_alliances_retention_month_3` (*Measure Names* on Colour, mark **Line**: Horde `#d25030`, other alliances `#5b6b7a`), "Newcomers still playing at month 3". Annotate November 2025: "Horde loses its space; its newcomers' retention falls to 8%".

**Robustness panel** (`robustness_equal_activity`): small bars, retention for "In a corp" vs "No corp" within each activity band; one line of text: "Even among equally active players: 1.5×".

## Act 4: What it's worth
**Headline:** *Buying newcomers got pricier. Only those in a group pay back their cost.* Shade every number on this page as an estimate.

**⭐ Spend up, signups down** (`unit_economics`): two small bar charts side by side, 2024 vs 2025: marketing (`#b08505`) and signups (`#5b6b7a`), each with its own axis and the change labelled ("+41%", "−10%"). Below them, cost per signup as a big number: $10.43 → $16.25.

**⭐ Payback bullet** (`newcomer_value`): Rows `segment` (sorted by `ltv_to_cac`), Columns `ltv_to_cac`, mark **Bar**; reference line at **1.0** labelled "pays back its cost". Bars below 1 in `#5b6b7a`, above in `#00a3c9`.

**MRR by quarter** (`revenue_quarterly`): Columns `quarter_start`, Rows `mrr_usd`, mark **Area**, money colour.

## Act 5: Recommendation
**Headline:** *Group and protect newcomers in their first week, then test it.*

**⭐ What-if slider** (`whatif_inputs`)
1. Create a parameter **Share moved into a group**: float, range 0 to 0.5, step 0.05, display as %.
2. Calculated field **Extra first-year revenue** = `[Share moved into a group] * SUM([newcomers_per_year]) * (SUM([value_in_group]) - SUM([value_alone]))`.
3. Text sheet showing it in big numbers; filter `scenario` to the first row; show the parameter control as a slider.
4. Caption: "Estimate, first year only; a test would measure it for real."

**A/B test card:** text box with the two arms (tutorial ends in the corporation finder vs today's solo missions) and the measures (month-3 retention, first-year revenue).

## Story assembly
- One story point per act, caption = the headline above.
- Same colour language everywhere: grey = alone, cyan = group or win, coral = death, violet = killed by the computer, gold = money.
- Event markers (`events`) as reference lines on every time chart.
- Last story point: the caveats in plain words (copy from `docs/story.md`).
