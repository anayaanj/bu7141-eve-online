# Argument inventory

Every argument the data supports, before deciding the order. Status: **in** = in the five-act story now · **new** = found 12 Oct 2026, not in the story · **fix** = a current claim that must change · **park** = true but not for the dashboard. "Act" is the recommended act under the current spine (1 setting · 2 the loss · 3 who stays · 4 money · 5 recommendation). Month-3 return = share seen again 3 months after the first month. "One-day" = seen on one day in the first month (221,056 of 356,769 newcomers we can see).

## A. Setting: a universe built by groups

| # | Argument | Evidence | Visual | Data | Act | Status |
|---|---|---|---|---|---|---|
| A1 | EVE has run for 23 years on one server, and every turning point in its history is a group: an alliance, a coalition, a betrayal. | 36,025 online at the 2011 peak, ~24,000 now; 500,000 subscribers at the 2013 peak; 19 turning points 2006–2018. | Players-online area with subscriber row and turning-point circles. | `players_history_monthly`, `great_wars` | 1 | in |
| A2 | Space is held by groups, never by one player, and control moves: empires rise and fall. | Goonswarm 117 → 509 systems; Horde 414 → 0; Fraternity 163 → 344; largest battle 4,367 pilots in one hour (4-HWWF, Apr 2026). | Animated alliance map with battle rings. | `sovereignty_monthly`, `war_zones_monthly`, `map_layers` | 1 | in |
| A3 | Half of everything made in EVE is made in alliance space. | Null-sec (sov) produced 49% of all ISK value in Jan 2024 and 55% in Aug 2026 (111T of 202T a month); high-sec flat at ~50T. | One tile, or a thin stacked area "value produced by area" under the map. | `economy_monthly` | 1 | in (side tile, 13 Oct) |
| A4 | The people who last are the ones in groups: veterans carry the game. | 64% of players active in Aug 2026 were created before 2024. | Tile. | `eve_at_a_glance` (veterans row) | 1 | in |
| A5 | EVE is not shrinking: late 2025 was its busiest stretch in five years. | 27,209 online in Dec 2025, the highest month since Apr 2020; 2025's peak (27,209) beat 2024's (24,706). | Annotation on the A1 timeline. | `players_history_monthly` | 1 | new |
| A6 | EVE keeps newcomers about as well as other MMOs; what is unusual is how it keeps veterans. | 12-month retention of newcomers 8.24%, the same as World of Warcraft 2006–07 measured the same way (30%/15%/11%/8% at months 1/3/6/12 vs WoW 28%/16%/11%/8%); SuperData's free-to-play average 6%. | Two retention curves on one chart, EVE vs WoW. | `retention_by_segment` (WoW rows), `mmo_comparison` | 1 or 2 footnote | new, but careful: the earlier Steam "share of peak" comparison confused readers and was cut. It reframes the loss as "normal churn, exceptional loyalty", which weakens the alarm in act 2. |
| A7 | The core is stable: daily users are a steady 13% of monthly users for 32 months. | DAU/MAU 0.130–0.143, ~16,000 a day / ~118,000 a month visible. | None (one line in caveats). | `dau_mau_monthly` | park | new |
| A8 | What EVE is famous for costs real money, and groups do it. | Players destroy about $0.7M of ships a month at the PLEX price; the costliest battle of the window, Atioth (Apr 2026), about $70K over three days; B-R5RB (2014) about $300K in 21 hours. | KPI tile + rings on the alliance map sized by dollars, five labelled. | `famous_battles`, `alliance_players` | 1 | in (13 Oct): the three costliest battles ever by side, and the alliances that fought them |
| A9 | Of 100 who sign up, one is still playing a year later. | 2.73M created Jan 2024–Aug 2026; 13% ever seen fighting or trading; 8.2% of those still active at month 12 → 1 in 100. Same base as act 2. | Funnel of dots, 100 → 13 → 1, then the same dots with one lit and "Why aren't new players staying?" | `signup_dots`, `kpi_tiles` | 1 (closer) | in (13 Oct); replaced the 12-month snapshot (950,000 → 105,000 → 24,000), which mixed character ages |
| A10 | The game is carried by old characters: 80% of active players have been here a year or more, and they pay twice as often. | Active Aug 2026 by character age: 10+ yrs 29%, 3–10 32%, 1–3 18%, under a year 20%; Omega in August 60% (1 yr+) vs 32% (under a year). | 100% bar by age + two tiles. | `active_by_character_age` | 1 | in (13 Oct); replaces the 64% veterans tile (A4) |

## B. The loss, and a newcomer's first day

| # | Argument | Evidence | Visual | Data | Act | Status |
|---|---|---|---|---|---|---|
| B1 | Of 100 who sign up, 99 are gone within a year. | 2.73M characters created; 13% ever fight or trade; 8.2% of those still active at month 12 → 87 / 12 / 1. CCP's own 2019 figure: 9 in 10 quit in the first week. | 100 dots. | `signup_dots`, `kpi_tiles` | 2 | in |
| B2 | Most newcomers we can see appear on a single day, and days seen predict return. | 62% seen on one day; 9.5% of them return at month 3 vs 45% of those seen on 8+ days. | Staircase bars. | `first_month_active_days` | 2 | in |
| B3 | For most, the only trace they leave is being killed by another player. | Of 100 we can see: 41 seen once and killed by a player, 7 by the computer, 14 seen once with a kill or trade, 38 seen on 2+ days. | Waffle. | `waffle_first_day` | 2 | in |
| B4 | They die on the way out: half of one-day deaths are in low-sec, and a few gate systems are the graveyard. | 51% of one-day newcomer deaths in low-sec, 19% high-sec, 21% null-sec; Ahbazon 8,407, Tama 5,315, Jita 4,478, Uitra 3,077, Ami 1,741 = 1 in 6 of 136,386. | Death map with the five hotspots named. | `casual_deaths_by_system` | 2 | in |
| B5 | "Only 0.15% die in a starter system" | **Wrong.** `is_starter_system` is the SDE school list (Ammold, Kisogo, Todaki…), not where new players spawn today. Uitra, the 4th deadliest system, is a newcomer home system and is not flagged. The 302-player count is an artefact. | Remove the tile and the white rings on the map. Replace with B6 or "51% die in low-sec". | `casual_first_day`, `casual_deaths_by_system` | 2 | fix |
| B6 | A third are killed within a week of creating their character, and they come back least. | 34% of one-day newcomers killed within 7 days of signup; their month-3 return 6.9% vs 10.8% for those killed later. | Tile, or a two-bar. | `casual_first_day` ("Killed in their first week") | 2 | new |
| B7 | Nobody had taken them in: most were still in the starter corporation. | 37% of one-day newcomers in the NPC starter corp; a further 15% in a 2–10 member corp (most likely alt corps). | Tile. | `casual_first_day` ("Their corporation") | 2 | in |
| B8 | Their first enemy is an eight-year veteran. | On first losses, 87% of player killers are pre-2024 characters; median killer age 8.2 years; killed by a veteran → 8.6% return vs 11.0% by a newer player. Veterans make 89% of all kills, so this is the baseline, not a cause. | Tile ("8 years: the median age of the character that kills a newcomer first"). | DB query; add to `casual_first_day` ("Killed by a veteran" row exists) | 2 | new (framing; was dropped in commit 7dfc993 as a comparison, works as a fact) |
| B9 | The gate systems are solo veteran hunters, not twenty-man camps. | Ahbazon: median 1 attacker, 53% solo, 93% veteran final blow; Tama: median 2, 45% solo, 91% veteran. Killed by 6+ attackers is rare (6%) and those newcomers return more (18–19%, fleet context). | Caption on the death map. | DB query (`killmail.attacker_count`) | 2 | new |
| B10 | It is not the money they lose that drives them away. | 63% of first losses are hulls worth under 1M ISK; 64% are a corvette, frigate or destroyer; a costlier first loss goes with *higher* return (100M+: 21% vs 13%). | One line, or a small bar by hull value. | DB query (`item_type.mean_isk_value`) | 2 (counter-argument killer) or 5 caveats | new |
| B11 | The game prepares them for something else: the tutorial and career missions are solo, against the computer. | EVE University wiki, *Getting Started in EVE Online*. | One line under the map. | qualitative | 2 | in |
| B12 | Expansions bring signups but not stayers. | Jun 2024 (Equinox) 115,029 signups, the window's high; expansion-month newcomers return 14% vs 15%. | Signups line with event markers. | `funnel_monthly`, `events` | 4 or park | in story text, no view |
| B13 | They die fast: the typical newcomer loses a ship 11 days after creating the character. | Newcomers we can see with a known signup date (316,226): median 11 days to first loss; 20% within a day, 44% within a week, 66% within a month. One-day newcomers: median 16 days, 39% within a week. | Tile ("11 days") or a small cumulative curve. | DB query (first loss per newcomer); export to add | 2 | new (13 Oct) |
| B14 | They die in the ship they started in. | First loss of one-day newcomers, by hull: frigate 40%, corvette 10%, destroyer 9%, shuttle 9%, cruiser 6%, capsule 5%, mining barge 3%, other 18%. Starter-class hulls (corvette, frigate, destroyer, shuttle) are 68%. | Small bar by hull class, or one line. | DB query; export to add | 2 | new (13 Oct) |
| B15 | At the gates it is the same few people. | Of 165,459 one-day newcomers' first losses to a player, 45,256 different characters took the final blow; the top 1,000 took 34%. At the hotspots it concentrates: in Ahbazon the top 20 killers take 60% of newcomer first losses (one 21-year-old character took 1,114 on its own); Uitra 69% (one character 927); Ami 50%; Tama 43%; Jita 25%. | Tile on the death map: "20 characters · 60% of Ahbazon's newcomer kills · the busiest has 1,114". | DB query (final-blow concentration); export to add | 2 | new (13 Oct), the strongest new one: it names a fixable thing |
| B16 | A quarter of low-sec deaths are the first jump out of safety. | Of one-day first losses to a player: 45% low-sec, 19% player null-sec, 16% high-sec, 12% wormholes; 25% of the low-sec deaths are in a system one gate from high-sec (Ahbazon and Tama are such gates). | Caption on the death map. | DB query (`stargate_link`); export to add | 2 | new (13 Oct); note the 51% low-sec figure in B4 counts all one-day deaths, this one counts first losses to a player |

## C. The ones who stay found a group

| # | Argument | Evidence | Visual | Data | Act | Status |
|---|---|---|---|---|---|---|
| C1 | In a group, in player space or with a win, one-day newcomers come back twice as often. | 6.9% → 15.0% (starter vs mid-sized corp); 6.3% → 14.4% (high-sec vs player null-sec); 8.5% → 17.3% (killed vs got a kill). | Dumbbells. | `come_back_pairs` | 3 | in |
| C2 | It is not just that keen players join groups. | At equal first-month activity, in a corp vs not: 11.2% vs 7.0% (1 day), 20.7% vs 13.7% (2–3), 36.2% vs 23.9% (4+). | Grouped bars. | `robustness_equal_activity` | 3 | in |
| C3 | When the group falls, its newcomers leave. | Horde's Nov 2025 cohort 8.0% vs 22.4% elsewhere; before the collapse Horde often beat the field (Dec 2024 32% vs 23%). | Stacked systems-held and retention lines. | `horde_story` | 3 | in |
| C4 | Not any group: the right-sized group. A 2–10 member corp is almost as useless as the starter corp; 201–1,000 is the sweet spot; the 50,000-member blocs dip. | Month-3 return, all newcomers: starter 9.6%, 2–10 11.1%, 11–50 17.3%, 51–200 20.8%, 201–1,000 22.8%, 1,000+ 18.3%. Month 12: 5.4% / 5.6% / 9.2% / 11.4% / 13.9% / 10.6%. | Ladder bars by corp size, starter in grey, 201–1,000 in cyan. | `retention_by_segment` (corp size rows) | 3 | new, and it sharpens the recommendation (route to mid-sized corps, not "any corp") |
| C5 | The stickiest first month is a big fleet fight. | Fought in a 100+ pilot battle in month one: 46% / 27% / 20% / 16% at months 1/3/6/12, double the average and 3.2× "neither" at month 12. 15,987 newcomers did. | Retention curves to month 12: neither, all, corp+kill, war. | `retention_by_segment` | 3 | new |
| C6 | Year-one survivors are almost all in groups. | Of 17,757 newcomers active at month 12: 92% in a player corp that month, 71% under an alliance tag, 52% had flown an Omega-only ship, 57% got a kill. | Tile, as the act's closer. | DB query (`character_month_activity`, `killmail_participant`) | 3 | new |
| C7 | Joining at all matters more than joining fast. | Fair cut (active at month 2): joined in month 0 → 37% at month 6, month 1 → 34%, month 2 → 28%, never → 17%. 94% of joiners join in month 0 anyway. | One line in act 5 (the test's timing). | DB query | 5 | new; tempers "week one": earlier is modestly better, never is the cliff |
| C8 | The group effect holds for traders too. | Non-combatants in a corp 15.4% vs 9.9% without; traded in month 1: 20.8% vs 12.2%. | Footnote. | `retention_by_segment`, `robustness_contracts_only` | 3 footnote | in (text) |
| C9 | Part of the corp effect is visibility. | Counting only contracts among traders, the corp gap shrinks or vanishes (6.6% vs 4.4%; 9.8 vs 8.9; 12.9 vs 13.6). | Caveat line. | `robustness_equal_activity` (contracts columns) | 5 caveats | new |
| C10 | Alts are in the data. | Newcomers who die in Abyssal deadspace on day one return 28% (vs 6–7% in high/low-sec): prepared players or veterans' alts, not beginners; 2,500 of them. | Caveat line. | `casual_first_day` ("Non-Universe") | 5 caveats | new |
| C11 | History agrees: what kept newcomers was belonging with support. | Goonswarm (2005) recruited and taught beginners others turned away; TEST (2010) grew to 3,000+ with free ships and replacement. | Two labelled turning points on A1. | `great_wars` | 1 or 3 | in |

## D. Money: buying vs keeping

| # | Argument | Evidence | Visual | Data | Act | Status |
|---|---|---|---|---|---|---|
| D1 | Buying a newcomer costs more every year. | Marketing $11.4M → $16.1M (+41%); signups 1.09M → 0.99M (−10%); cost per signup $10.43 → $16.25 (+56%); per engaged newcomer $93 → $117 (+26%, because engaged newcomers rose 12%). | Single-base cost table. | `acquisition_cost_by_year` | 4 | in |
| D2 | The average newcomer does not pay back the spend; one who stays the year pays it back four times. | $102 (2.4 active months × $43) vs $511 vs $117 of marketing. | Two bars against a dashed line. | `unit_economics`, `newcomer_value` | 4 | in |
| D3 | Only grouped newcomers pay back their cost. | 0.6× starter corp, 0.7× no corp no kill, 0.9× average, 1.1× corp and a kill. | Payback bullet with the 1.0× line. | `newcomer_value` | 4 | in |
| D4 | The ceiling on what leaving costs. | $409 per newcomer who leaves instead of staying the year; × 137,035 = $56M a year against $60.8M revenue. | Tiles. | `unit_economics` | 4 | in |
| D5 | Groups don't just keep newcomers, they turn them into paying players. | Flew an Omega-only ship within 12 months: corp + kill 35% vs neither 14%; corp 201–1,000 44% vs starter corp 15%; player null-sec 45% vs high-sec 17%. Even one-day newcomers in a 201–1,000 corp convert 37% vs 12% in the starter corp. | Paired bars: month-3 return and Omega conversion by group, one 0–50% axis. | `conversion_by_segment` | 4 | new, the strongest new argument: it is the monetization proof the story lacked |
| D6 | CCP cannot afford to buy newcomers it does not keep. | 2025: operating result −$26.6M, net −$14.0M, R&D $58.2M, marketing $16.1M, total revenue flat at ~$70M (2022–2025). | Tile or caption. | `ccp_annual` | 4 | new; caveat: CCP ehf's audited accounts cover all of CCP, and R&D includes other projects |
| D7 | Players already pay for commitment. | Jul 2025 restructure: 24-month Omega at $11/month vs $20 monthly; deferred subscriptions +53% (3.47M → 5.31M) in 2025. | None, or one line. | `omega_prices`, `ccp_annual` | park | new |
| D8 | Newcomer retention is improving on its own. | Month-3 return of engaged newcomers 14.0% (2024) → 15.1% (2025) → 16.1% (Jan–May 2026); peak 18.3% for the Jan 2026 cohort. The engaged share drifted down (~15% → ~13%). | Line by cohort month with event markers (Omega restructure Jul 2025, Catalyst Nov 2025). | `cohort_heatmap`, `funnel_monthly`, `events` | 4 or 5 | new; a real finding and an honest complication ("something is working: find out what") |
| D9 | Expansions bring back veterans, not newcomers. | Returners were 17% of active players in Catalyst's month (23,311), 12–15% in 2026; expansion-month newcomers no stickier (B12). | Returners share line with expansion markers. | `returners_monthly` | 4 | in story text, no view |
| D10 | Revenue has grown without growing the player base. | Subscription and in-game revenue $47.1M (2022) → $60.8M (2025), +29%, while players online stayed ~23–24K: veterans pay more. North America 52% of external revenue; Asia −33% since 2022. | None, or a tile. | `ccp_annual` | park | new |
| D11 | MRR by quarter. | Pearl Abyss KRW figures converted. | Dropped: no newcomer link, third base on the page. | `revenue_quarterly` | — | dropped |

## E. Recommendation and the test

| # | Argument | Evidence | Visual | Data | Act | Status |
|---|---|---|---|---|---|---|
| E1 | Moving lone newcomers into a group with a win is worth money, and it can be sized. | 44,452 lone engaged newcomers a year × $47 more each = $0.21M per 10% moved; $1.0M at 50% (1.7% of revenue). Scenario 2: 30,423 one-day starter-corp newcomers × $29. | What-if slider. | `whatif_inputs` | 5 | in |
| E2 | End the tutorial in the corporation finder; route to a 201–1,000 member corp; give a first fight they can win, in a fleet. | C1, C4, C5. | Text. | — | 5 | in, sharpen with C4/C5 |
| E3 | Test it before rolling it out. | A/B: half end the tutorial in the corp finder, half in solo missions; measure month-3 return, Omega conversion (D5) and first-year revenue. | Text card. | — | 5 | in, add conversion as a measure |
| E4 | One in ten early drop-outs comes back on their own: a re-engagement target. | 65% of newcomers are inactive at months 1–2; 9.8% of those are seen again at months 3–6 (18,359). | Tile. | DB query | 5 | new |
| E5 | The new owners are getting more people to try EVE, but not through week one. | Since the May 2026 sale: signups +13% a month, active players −4%; Steam positive share fell to 62% in Jun–Jul 2026, the window's low; ownership forum posts spiked (215 in May 2026). | Tile + one sentiment line. | `sale_before_after`, `signals_monthly` | 5 | in (tile), sentiment new |
| E6 | Caveats. | 13% visible; one-day ≠ played one day; activity not logins; link not proof (C9); money is an upper bound; characters not people (C10); the starter-system flag is wrong (B5). | Text. | — | 5 | in, add C9, C10, B5 |

## What changes if we take the new ones
- **Act 2 loses a false claim** (B5) and gains two sharper ones (B6 first-week kills, B8/B9 who kills them). The death map keeps its hotspots but drops the white rings.
- **Act 3 gets its missing "which group"** (C4 corp-size ladder) and its strongest single factor (C5 fleet fights), plus a closer (C6: survivors are all grouped).
- **Act 4 gets the monetization proof** (D5 Omega conversion by group) and the stakes (D6 CCP's loss). D8 (retention improving) is the one new finding that complicates the story and should be decided on, not buried.
- **Act 5** adds the second-chance returners (E4), conversion as an A/B measure (E3) and three caveats.
- **Setting** can take A3 (alliance space makes half the economy) and A5 (busiest stretch in five years) without a new chart.

## Exports needed for the new ones
B6/B8 from `casual_first_day` (rows exist). C4, C5 from `retention_by_segment` (exists). D5 from `conversion_by_segment` (exists). A3 from `economy_monthly` (exists). New SQL for B9 (attackers on first loss), B10 (first-loss hull value), B13–B16 (first loss: timing, hull class, killer concentration, border systems), C6 (survivors' corp/alliance at month 12), E4 (second-chance rate), and a `casual_deaths_by_system` fix dropping `is_starter_system`.

## Can Tableau Public build it

Every visual above, by form. "Native" = standard Tableau marks, no tricks. All exports are long format, which Tableau prefers.

| Visual | Arguments | Build in Tableau | Verdict |
|---|---|---|---|
| Tiles | A3 A4 B6 B7 B8 C6 D4 D6 E4 E5, all act tiles | One text sheet per number (Tableau Bold + muted label). No dotted borders on containers: mark estimates with a label and 50% opacity instead. | Native |
| Timeline with turning points and an annotation | A1 A5 C11 | Area + dual-axis circle on `players_history_monthly` related to `great_wars` by month; reference band for 2024–26; *Annotate > Point* for Dec 2025. | Native |
| Animated alliance map | A2 | Scatter on `map_x`/`map_y` allows only two axes, so links + systems + battle rings do not fit as a dual axis. Use **Map Layers**: scale x/y into lat/lon ranges, `MAKEPOINT`, background map *None*, one layer each for links (Line), systems (Circle, alliance colour), battles (Circle, size, no fill). `month` on **Pages**. Auto-play only runs in Tableau Desktop/Public app; on the web the viewer steps months with the page control. | Works; animation is manual on the web |
| Stacked area, value produced by area | A3 | `economy_monthly`: `month` × `produced_isk`, `area` on Colour, mark Area. | Native |
| EVE vs WoW retention curves | A6 | `retention_by_segment`: `k` on Columns, `retention` on Rows, `game` on Colour, filter the two "All new players" rows. | Native |
| 100 dots, waffle | B1 B3 | `x` and `y` as dimensions, mark Circle / Square, `kind` / `category` on Colour, gridlines off. | Native |
| Bars: staircase, ladder, grouped, paired | B2 C2 C4 D5 | Standard bars. D5 relates `conversion_by_segment` to `retention_by_segment` (k = 3) on `segment`, *Measure Names* on Colour, one 0–50% axis. C4 filters the six "Corp size" segments. | Native |
| Death map with hotspots and caption | B4 B9 | Same map, systems only: size and colour by `casual_newcomers_killed`, five annotations, caption as a text object. Dropping the white rings (B5) also drops a layer. | Native |
| Small bars by first-loss hull value | B10 | Needs a new export; then a plain bar. | Native once exported |
| Dumbbells | C1 | `alone_` and `together_retention_month_3` on a synchronised dual axis, Circle + Line with *Path*. | Native, in the guide |
| Retention curves to month 12 | C5 | As A6 with `segment` on Colour, filter four segments. | Native |
| Horde: systems over retention | C3 | Two measures on Rows share `month` on Columns: two panes, two charts, no shared scale. | Native, in the guide |
| Cost table by year | D1 | Tableau formats by measure, not by row, so add a string calc (`CASE [measure] …`) for the display and keep `value` for sorting; `change_vs_prior` coloured by sign. | Native with one calc |
| Bars against a dashed line, payback bullet | D2 D3 | Bars + reference line (constant or parameter), dashed in *Format*. | Native, in the guide |
| What-if slider | E1 | Parameter (0–50%, step 5%) + calculated field; parameter controls work on Public. | Native, in the guide |
| Line with event markers | B12 D8 D9 | Line on `funnel_monthly` / `cohort_heatmap` / `returners_monthly`. `events` cannot drive reference lines directly: annotate the expansion months or relate `events` by month as a dual-axis mark. | Native |
| Sentiment line | E5 | `signals_monthly.steam_positive_share` by month. | Native |
| Text cards, caveats | E2 E3 E6 | Dashboard text objects. | Native |

Not reproducible, and not needed: the prototype's D3 transitions, hover highlights and Rajdhani/Barlow fonts (Tableau Public renders Tableau Book). Keep in mind: a Story adds its navigator above each point, so size the story so the 1366 × 768 dashboards are not scaled down (Story > Size, custom, about 1366 × 820).
