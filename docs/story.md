# Why EVE loses its newcomers

**For:** CCP Games (now Fenris Creations), the team that runs EVE Online's subscriptions.

**Question:** EVE's veterans stay for decades, but almost every newcomer is gone within a year. Why, and what could keep them?

**Thesis:** EVE is built by groups. Newcomers arrive alone and leave. Grouping them in their first week is the cheapest growth lever CCP has, and it should be tested.

**Spine (diagnosis first, money as stakes):** the setting plants the idea that everything that lasts in EVE is a group → the loss, and what a newcomer's one day looks like → the few who stay found a group → what buying a newcomer costs and what keeping one pays → the recommendation and the test. Money appears once, in act 4, after the audience knows the cause.

All numbers come from `data/exports/` (built by `db/analysis.sql` and `scripts/export.sh`). The interactive prototype is `prototype/index.html` (published at https://claude.ai/artifact/7ERYA6wEi2T7TnYkzE2Xsd).

## Words the audience needs (one box on page 1)
- **Corporation:** a player-run group, like a guild or a company. **Alliance:** a group of corporations. New players start in a computer-run **starter corporation**.
- **ISK:** the in-game money. **PLEX:** an item bought with real money and sold to other players for ISK.
- **Alpha / Omega:** free account / paid subscription. Some ships can only be flown with Omega.
- **High-sec / low-sec / null-sec:** policed space / partly lawless space / lawless space held by player alliances.
- **Veteran:** a character created before 2024.
- **PvE / PvP:** fighting the computer / fighting other players.

## The story (one dashboard page each)

### 1. What is EVE?
**Headline:** *One world for 23 years. Of 100 who sign up, one is still playing a year later.* Set the stage (scale, the zones, the money), show who plays today, then the funnel that asks act 2's question. The slide deck tells the same act in eight slides; the dashboard page holds the six visuals below.
- **Players online, by year (bars, 2006–2026, `players_history_monthly.csv`):** yearly average of players online, peak 32,720 in 2013 highlighted, 2024–2026 in the accent colour as this story's data (25,046 in 2026).
- **Most of it has no police (map + bars, `map_layers.csv`):** the 5,485 systems coloured by security band, high-sec blue, low-sec yellow, null-sec red, with the count of systems in each: 1,246 · 687 · 3,294. High-sec is where every newcomer starts; null-sec is where players make the law.
- **Largest alliances (bars, `alliance_players.csv`):** characters seen fighting under the tag, 2024–2026: Goonswarm 54,021 · Fraternity 44,564 · Pandemic Horde 43,552 · the other alliances in the three battles below, 69,433 together.
- **Costliest battles ever (stacked bars, `famous_battles.csv`):** M2-XFE (Dec 2020) 29.1T ISK ≈ **$378,000** · B-R5RB (Jan 2014) 11T ISK ≈ **$300,000** · Atioth (Apr 2026, our own killmails, hulls only) 6.6T ISK ≈ **$70,000**. Each bar split by side: Goonswarm's side in cyan in all three (M2-XFE and B-R5RB split by Titans lost per side, 123 vs 121 and 16 vs 59; Atioth by ship value, Goonswarm lost $57K of the $70K).
- **Who plays today (100% bar + two tiles, `active_by_character_age.csv`):** 118,000 characters active in August 2026 by age of the character: 10+ years 29% · 3–10 years 32% · 1–3 years 18% · under a year 20%. **80% veterans** (a year or more; 60% flew an Omega-only ship in August) vs **20% in their first year** (32%). The word "newcomer" is kept for the cohort followed from day one.
- **Of 100 who sign up (funnel of dots, `signup_dots.csv`, `kpi_tiles.csv`):** **2.73 million** characters created Jan 2024–Aug 2026 → **357,000** ever seen fighting or trading (13%) → **1 in 100** still playing a year later (8.2% of those seen are active 12 months after their first month). A hundred dots, thirteen, one: *only one in a hundred is still playing a year later.* This is the story's base from here on; seen means a killmail or a contract, so quiet players are not counted.
- **How real money enters the game (two tiles, `plex_monthly.csv`):** $1 ≈ 105M ISK (a PLEX sells for 5.2M ISK in game; CCP sells 500 for $24.99) · a month of Omega is $20 or 2.6B ISK. Every dollar figure in the story is ISK at that month's PLEX price. The players' money, not CCP's: CCP's money waits for act 4.
- **Handoff:** why aren't new players staying?

### 2. Newcomers arrive alone, and leave
**Headline:** *Of 100 newcomers, 99 are gone within a year. Most leave after one day, alone.* Two bases on this page, labelled on every panel: "of 100 who sign up" and "of 100 we can see" (the 13 who fight or trade, scaled to 100).
- **100 sign up (dots, `signup_dots.csv`):** **2.73 million** characters were created from January 2024 to August 2026. **87** are never seen fighting or trading with another player, **12** are seen and then gone within the year, **1** is still playing a year later: only **13%** ever engage, and **8.2%** of those are still active at month 12 (`kpi_tiles.csv`). CCP's own number (EVE North, 2019): 9 in 10 new players quit in the first week.
- **Their first month (waffle, `waffle_first_day.csv`):** of 100 we can see, **41** are seen once and killed by another player, 7 seen once and killed by the computer, 14 seen once with a kill or a trade, 38 seen on 2+ days.
- **Seen on more days, seen again later (staircase, `first_month_active_days.csv`):** **62%** appear on just one day in their first month. Only **9.5%** of them are seen again 3 months later, against **45%** of those seen on 8+ days.
- **Where the one-day newcomers die (map, `casual_deaths_by_system.csv`):** safe at home, only **0.15%** were killed by a player in a starter system (white rings). They die after heading out alone, mostly in low-sec (35%) and high-sec (24%). **About 1 in 6 died in just five systems** out of 5,485: Ahbazon (8,407), Tama (5,315), Jita, the main trade hub (4,478), Uitra and Ami.
- **Tiles (`kpi_tiles.csv`, `first_month_active_days.csv`, `casual_first_day.csv`):** **1 in 100** signups still playing a year later · **62%** seen on a single day · **0.15%** killed in a starter system (34% killed within a week of creating their character) · **37%** still in the starter corporation: no group had taken them in.
- **The game prepares them for something else.** The official tutorial and career missions are solo and teach fighting the computer, with little training for fighting players (EVE University wiki, *Getting Started in EVE Online*). One line under the map.
- **Handoff:** the few who return: what did they have that the others didn't?

### 3. The ones who stay found a group
**Headline:** *Newcomers in a group come back twice as often.*
One-day newcomers seen again 3 months later, alone vs together (`come_back_pairs.csv`):

| Alone | | In a group or with a win | |
|---|---|---|---|
| In the starter corporation | 6.9% | In a mid-sized player corporation (201–1,000) | **15.0%** |
| In high-sec | 6.3% | In player-held null-sec | **14.4%** |
| Killed by another player | 8.5% | Got a kill and survived | **17.3%** |

- **Each pair roughly doubles the chance of coming back** (2.0–2.3×).
- **It holds under our strictest test (`robustness_equal_activity.csv`):** comparing players who were equally active in their first month, those in a corporation still come back **1.5–1.6×** as often in every activity band (1 day: 7.0% vs 11.2%; 2–3 days: 13.7% vs 20.7%; 4+ days: 23.9% vs 36.2%). This panel uses all newcomers we can see, and says so.
- **This is a link, not proof.** Player-space numbers are partly visibility: players there fly in fleets and show up more.
- **When the group falls, its newcomers leave (`horde_story.csv`):** Pandemic Horde took in more newcomers than any other alliance (8,203 to October 2025). It lost almost all its space in November–December 2025 (414 systems → 59 → 0 by April 2026). Before that, its newcomers stayed slightly more often than other alliances' (22% vs 20% at month 3); the November 2025 cohort only **8% vs 22%**. One case, not proof, but it points the same way.
- **Tiles:** **2×** in a group, in player space or after a win · **1.5–1.6×** among equally active players · **414 → 0** systems Horde held, Nov 2025 → Apr 2026 · **8% vs 22%** for Horde's November 2025 newcomers.
- **History agrees** (Groen, *Empires of Eve*): veterans have hunted newcomers since 2003, and what worked was belonging with support. TEST grew from a Reddit group to 3,000+ members with a place to learn, free starter ships and ship replacement.
- **Handoff:** keeping a newcomer means grouping them. What does buying one cost, and what does keeping one pay?

### 4. Buying newcomers costs more every year; keeping them pays
**Headline:** *A signup now costs $16. Only grouped newcomers pay back their cost.* Every number on this page is an estimate from CCP's audited accounts; dash every panel and tile (`unit_economics.csv`, `acquisition_cost_by_year.csv`, `newcomer_value.csv`). Base: per engaged newcomer, 2025, except the one "per signup" row, which says so.
- **What buying a newcomer costs (table, one labelled scale per row, `acquisition_cost_by_year.csv`):** marketing **$11.4M → $16.1M** (+41%), signups 1.09M → 0.99M (−10%), engaged newcomers 122,000 → 137,000 (+12%), cost per signup **$10.43 → $16.25** (+56%), cost per engaged newcomer **$93 → $117** (+26%). Never two axes on one chart: the table replaces the old "spend up, signups down" pair.
- **Revenue in year one vs the marketing it took (bars, `unit_economics.csv` 2025 + `newcomer_value.csv` "All new players"):** at **$43** of revenue per active player a month, the average engaged newcomer (active **2.4 months** in year one) brings in **$102**; a player who stays the year brings in **$511**; a dashed line at the **$117** of marketing it took to bring one in.
- **Who pays back their cost (bullet, `newcomer_value.csv`):**

| Newcomer | Active months in first year | First-year value | vs cost to acquire ($117) |
|---|---|---|---|
| One-day, in the starter corporation | 1.7 | $72 | **0.6×** |
| No corporation, no kill | 1.9 | $80 | 0.7× |
| One-day, in a mid-sized corporation | 2.4 | $101 | 0.9× |
| Average newcomer | 2.4 | $102 | 0.9× |
| Joined a corporation and got a kill | 3.0 | $127 | **1.1×** |

- **Tiles:** **$16.25** per signup (from $10.43) · **$117** per engaged newcomer · **$409** of first-year revenue not earned for each newcomer who leaves instead of staying the year ($511 − $102) · **$56M a year** not earned from 2025's 137,035 engaged newcomers (they would have paid $70.0M had all stayed the year; they paid $13.9M), nearly a second EVE against **$60.8M** of revenue. A ceiling, not a forecast: nobody keeps every newcomer.
- Dropped from this page: MRR by quarter (`revenue_quarterly.csv`, a KRW-converted estimate with no newcomer link), ARR prose, and "launches bring people, not stayers" (expansion-month newcomers stay no longer than others, 14% vs 15%; Catalyst brought back 23,311 returning players). They stay in the README's KPI coverage.
- **Handoff:** if grouping doubles return and pays back the spend, how much is it worth, and how would we know it works?

### 5. Group them in week one, then test it
**Headline:** *Put newcomers in a group in week one. Then test it.*
- **What-if slider (`whatif_inputs.csv`):** "% of newcomers moved into a group" → extra first-year revenue. Scenario 1: **44,452** engaged newcomers a year play alone (no corporation, no win); each would bring **$47** more in year one in a group with a win ($127 vs $80). Every 10% moved adds about **$0.21M**; 50% adds $1.0M, 1.7% of 2025 revenue. Scenario 2: 30,423 one-day newcomers in the starter corporation moved into a mid-sized corporation, $29 more each. First year only; a test would measure it for real.
- **Tiles:** **44,452** lone engaged newcomers a year · **+$47** each if grouped · **+13% signups** a month since the sale of CCP to its management (May 2026) while active players moved −4% (`sale_before_after.csv`): more people are trying EVE; will the new owners get them through week one?
- **What to do:** end the tutorial in the corporation finder, not in solo missions, and route newcomers from the starter corporation into a mid-sized player corporation (the game already has a corporation finder and teaching corporations such as EVE University). Give them a first fight they can win, with a group. Spend on keeping as well as buying: a newcomer in a group pays back their cost in year one; one alone covers about 60%.
- **A/B test:** half of new players end the tutorial in the corporation finder, half in today's solo missions; measure month-3 return and first-year revenue. It would turn our strongest lead into proof.
- **Caveats, on this page in plain words** (no separate caveats page):
  - **We see 13% of new characters in detail:** those who fight or trade. Signups, players online and revenue cover everyone.
  - **"One-day" means seen on one day,** not played on one day. Some play quietly and only appear when killed. Activity is killmails and contracts, not logins: a player who stops fighting and trading looks like they quit.
  - **A link, not proof.** Keen players may join groups more often; the equal-activity check and the Horde case reduce but don't remove this.
  - **Money figures are estimates and upper bounds.** All revenue is put on visible players, newcomers pay less than veterans, and marketing covers all of CCP. The comparison between groups is the point, not the exact dollars.
  - **Characters, not people.** One account can have up to three characters, and a player can have several accounts.

## Dashboard rules
- One headline per page, written as the finding, and one handoff line at the bottom that asks the question the next page answers.
- State the base on every panel: "of 100 who sign up", "of 100 we can see", "one-day newcomers", "per engaged newcomer, 2025".
- No game jargon without the glossary.
- The same event markers on every time chart (`events.csv`).
- Estimates (money per player, cost per newcomer) shaded differently from official figures.
- Never two y-scales on one chart.

## Path B (kept for later)
The broader version of acts 2–3: all new players instead of one-day newcomers. "What the stayers have in common": joined a corporation and got a kill (24% at month 3 vs 9%), fought in a 100+ pilot battle (27%), mid-sized corporations (23%), with the robustness checks (`retention_by_segment.csv`, `robustness_contracts_only.csv`, `robustness_equal_activity.csv`). The effect is 1.4–2× overall and disappears for already-committed players, which is why the one-day focus is the main path.
