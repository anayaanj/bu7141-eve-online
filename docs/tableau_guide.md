# Tableau build guide

How to build the dashboard for `docs/story.md` in Tableau Public, one story point per act, in an EVE Online look.

## Setup (once)
1. **Palette:** copy `tableau/Preferences.tps` into `~/Documents/My Tableau Repository/` (replace the empty default), then restart Tableau. You get four palettes: *EVE story*, *EVE alliances*, *EVE heat*, *EVE security*.
2. **Open** `tableau/eve_story.twb`. Every file in `data/exports/` is already connected as an extract (`tableau/extracts/`), which Tableau Public needs before it can save.
3. **After changing the data:** rerun `./scripts/export.sh`, then `python3 scripts/make_workbook.py` (needs `python3 -m pip install tableauhyperapi`), then reopen the workbook.
4. **Saving:** Tableau Public saves to your public profile. Use *File > Save to Tableau Public*; you can hide the workbook on your profile while it's a draft.

## The EVE look
| Element | Setting |
|---|---|
| Dashboard and sheet background | `#070b10` (Format > Shading > Worksheet and Pane) |
| Panels (containers) | `#0d141c`, 1 px border `#1f3344` |
| Text | `#d7e2ec`; muted labels `#8195a8` |
| Accent (group, win, highlight) | `#4fd1ff` |
| Alone / starter corporation | `#5b6b7a` |
| Money | `#f2c45a`; death or loss `#ff6b4a` |
| Gridlines and axes | none, or `#1f3344` at 50% |
| Fonts | Tableau Public renders in the browser, so use *Tableau Book* / *Tableau Bold*. Titles in capitals, letter-spaced, in the accent colour. |
| Estimates | dotted borders or 50% opacity, with an "estimate" label |

Set it once: *Format > Workbook* (fonts, colours), then *Format > Shading* on each sheet. Dashboard size: **1366 × 768** (fixed), one dashboard per act, combined in a **Story** (*Story > New Story*), with the story point captions written as the finding.

## Act 0: What is EVE Online?
**Headline:** *One universe. 24,000 players online. Empires rise and fall.*

**⭐ Animated territory map** (`map_layers` related to `sovereignty_monthly`)
1. Data source `map_layers`: *Data > Edit Relationships*, add `sovereignty_monthly`, relate `solar_system_id = solar_system_id`.
2. Columns: `map_x` (dimension, continuous). Rows: `map_y` twice. Right-click the second `map_y` > *Dual Axis* > *Synchronize Axis*. Reverse the y axis if north looks upside down (*Edit Axis > Reversed*). Hide both axes.
3. First mark card (lines): mark type **Line**, filter `layer = link`, *Detail* `link_id`, *Path* `point_order`, colour `#1f3344`, size small.
4. Second mark card (systems): mark type **Circle**, filter `layer = system`, *Colour* `colour_group` (palette *EVE alliances*, "Other" in `#3a4652`), size very small.
5. Drag `month` (from `sovereignty_monthly`) to **Pages**. Show the history trail off, speed medium. The play button animates 32 months: Pandemic Horde vanishes around December 2025 and Goonswarm spreads.
6. Tooltip: system name, alliance, month.

**History strip** (`great_wars`): Columns `date` (continuous, exact date), Rows nothing, mark **Circle**, *Label* `event`; tooltip `what_happened`, `scale`, `source`. Height about 120 px across the top.

**Side panel tiles** (`eve_at_a_glance`, `dau_mau_monthly`): one text sheet per number (big number in Tableau Bold, label in muted text). DAU / MAU as a small line with the last value labelled (13%).

## Act 1: The paradox
**Headline:** *EVE keeps its veterans. It loses almost every newcomer.*

**⭐ Funnel** (`kpi_tiles`): three bars, signups 2,733,207 → engaged 356,769 → still playing after a year (engaged × 8.2% ≈ 29,000). Use a calculated field per stage, horizontal bars centred (put a negative half-width on a dual axis), labels with the number and share.

**Slope chart** (`mmo_comparison`, filter `metric = steam_share_of_peak_month_after_12_months`): Columns two constants (`"Peak month"` = 1, `"A year later"` = value), mark **Line**, *Detail* `game`; EVE in accent, others grey; label the ends. Footnote: "Mature games vs new launches: a sense of scale."

## Act 2: A newcomer's first day
**Headline:** *For most newcomers, the only trace they leave is their death.*

**⭐ Waffle** (`waffle_first_day`): Columns `x` (dimension), Rows `y` (dimension), mark **Square**, *Colour* `category` (killed by a player `#ff6b4a`, by the computer `#b9573f`, other `#5b6b7a`, seen on 2+ days `#4fd1ff`), size maximum, no gridlines. Title: "100 newcomers we can see".

**Staircase** (`first_month_active_days`): Columns `days_seen_first_month`, Rows `retention_month_3`, mark **Line** (step: right-click the line > *Line type: stepped*), label each step. Annotate 9.5% at 1 day and 45% at 8+.

**Where they die** (`map_layers` related to `casual_deaths_by_system`): same dual-axis map as act 0; systems sized and coloured by `casual_newcomers_killed` (palette *EVE heat*), starter systems (`is_starter_system`) as a white ring. Annotate the five hotspots: Ahbazon, Tama, Jita, Uitra, Ami.

## Act 3: The few who come back
**Headline:** *Newcomers in a group, in player space or with a win come back twice as often.*

**⭐ Dumbbell** (`come_back_pairs`): Rows `pair`; Columns `alone_retention_month_3` and `together_retention_month_3` on a dual axis (synchronised). First mark **Circle** (grey), second **Circle** (accent); add a **Line** between them with *Measure Values* and *Path*. Label both ends.

**⭐ Pandemic Horde** (`horde_story`): Columns `month`. Rows `horde_systems` (mark **Area**, `#3a4652`) and, on a dual axis, `horde_retention_month_3` and `other_alliances_retention_month_3` (*Measure Values*, mark **Line**, Horde in `#ff6b4a`, others in accent). Annotate November 2025: "Horde loses its space: its newcomers' retention falls to 8%".

**Robustness panel** (`robustness_equal_activity`): small bars, retention for "In a corp" vs "No corp" within each activity band; one line of text: "Even among equally active players: 1.5×".

## Act 4: What it's worth
**Headline:** *Buying newcomers got pricier. Only those in a group pay back their cost.* Shade every number on this page as an estimate.

**⭐ Spend up, signups down** (`unit_economics`): Columns `year`; Rows `marketing` (bars, `#f2c45a`) and `signups` (line, accent) on a dual axis. Label: "+41% spend, −10% signups".

**⭐ Payback bullet** (`newcomer_value`): Rows `segment` (sorted by `ltv_to_cac`), Columns `ltv_to_cac`, mark **Bar**; reference line at **1.0** labelled "pays back its cost". Bars below 1 in `#5b6b7a`, above in accent.

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
- Same colour language everywhere: grey = alone, accent = group or win, gold = money, coral = death.
- Event markers (`events`) as reference lines on every time chart.
- Last story point: the caveats in plain words (copy from `docs/story.md`).
