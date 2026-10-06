# Why EVE loses its newcomers

**For:** CCP Games (now Fenris Creations), the team that runs EVE Online's subscriptions.

**Question:** EVE keeps its veterans like few games do, but loses almost every newcomer. Why, and what could keep them?

**Answer:** most newcomers we can see show up on a single day, and for most of them the only trace they leave is being killed by another player, alone, after leaving the starter systems. The few who come back were in a player group, in player-held space, or got a win. They are also the only newcomers who earn back what it cost to bring them in. Getting newcomers into groups in their first week is the strongest lead, and worth testing.

All numbers come from `data/exports/` (built by `db/analysis.sql` and `scripts/export.sh`).

## Words the audience needs (one box on page 0)
- **Corporation:** a player-run group, like a guild or a company. **Alliance:** a group of corporations. New players start in a computer-run **starter corporation**.
- **ISK:** the in-game money. **PLEX:** an item bought with real money and sold to other players for ISK.
- **Alpha / Omega:** free account / paid subscription. Some ships can only be flown with Omega.
- **High-sec / low-sec / null-sec:** policed space / partly lawless space / lawless space held by player alliances.
- **Veteran:** a character created before 2024.
- **PvE / PvP:** fighting the computer / fighting other players.

## The story (one dashboard page each)

### 0. What is EVE Online?
One shared universe where everything is made, traded, fought over and destroyed by players.
- **History:** alliances have fought wars over territory since 2003, with spies, betrayals and coalitions that act like nations. The Bloodbath of B-R5RB (2014) destroyed the equivalent of over US$300,000 in ships (`great_wars.csv`, from Groen, *Empires of Eve*, Vols. 1 and 2).
- **Today:** about **24,000 players online at any moment**; on a given day about **13%** of the month's active players play (DAU / MAU: 16,000 / 119,000). About **16,000 ships are destroyed every day**; the largest battle drew **4,367 pilots in one hour** (4-HWWF, April 2026).
- **Empires rise and fall:** Pandemic Horde held 414 systems in November 2025 and none by April 2026; Goonswarm grew from 117 to 509, the largest empire on the map.
- **Main visuals:**
  - **Who holds space, by month:** the alliance holding each system, animated (`sovereignty_monthly.csv`, `map_systems.csv`, `map_links.csv`). Visual reference: Verite Rendition's influence maps (verite.space).
  - **History timeline:** 25 turning points, 2003–2018, as a strip along the top (`great_wars.csv`).
- **Side panel:** headline numbers and DAU / MAU (`eve_at_a_glance.csv`, `dau_mau_monthly.csv`); the economy by month as in CCP's Monthly Economic Report (`economy_monthly.csv`); the war-zone map (`war_zones_monthly.csv`).

### 1. The paradox: loyal veterans, vanishing newcomers
- **EVE is niche:** at its peak it had **500,000 subscribers** (2013), against 12 million for World of Warcraft.
- **Its players stay:** on Steam, EVE kept **84%** of its peak-month players a year later. Big recent launches kept 8–24% (New World, Throne and Liberty, Lost Ark).
- **Its newcomers don't:** **2.73 million** characters were created from January 2024 to August 2026. Only **13%** ever fought or traded with another player, and **8.2%** of those were still playing a year later, about **1 in 100** signups. CCP's own figure (2019): 9 in 10 new players quit in the first week.
- **Veterans still carry the game:** in August 2026, pre-2024 characters were still 64% of active players.
- Views: comparison with other MMOs (`mmo_comparison.csv`); funnel from signup to still playing (`funnel_monthly.csv`, `kpi_tiles.csv`).

### 2. A newcomer's first day
- **Most newcomers are seen on a single day.** **62%** of the new players we can see appear on just one day in their first month. Only **9.5%** of them are seen again 3 months later, against **45%** of those seen on 8+ days (`first_month_active_days.csv`).
- **For most, the only trace they leave is their death** (`casual_first_day.csv`):
  - **67%** were killed by another player, 11% by the computer.
  - **34%** were killed within **a week of creating their character**.
  - They are safe at home: only **0.15%** were killed by a player in a starter system. They die after heading out alone, mostly in low-sec (35%) and high-sec (24%). **37%** were still in the starter corporation.
  - **About 1 in 6 died in just five systems** out of 5,485: Ahbazon (8,407), Tama (5,315), Jita, the main trade hub (4,478), Uitra and Ami (`casual_deaths_by_system.csv`).
- **The game prepares them for something else.** The official tutorial and career missions are solo and teach fighting the computer, with little training for fighting players (EVE University wiki, *Getting Started in EVE Online*).
- Views: what happened on the one day (bar), where they died (map of casual deaths, `casual_deaths_by_system.csv`).

### 3. The few who come back
Casual newcomers seen again 3 months later, side by side (`casual_first_day.csv`):

| Alone | | In a group or with a win | |
|---|---|---|---|
| In the starter corporation | 6.9% | In a mid-sized player corporation (201–1,000) | **15.0%** |
| In high-sec | 6.3% | In player-held null-sec | **14.4%** |
| Killed by another player | 8.5% | Got a kill and survived | **17.3%** |

- **Each pair roughly doubles the chance of coming back.**
- **It holds under our strictest test.** Counting only trading activity, and comparing players who were equally active, casual newcomers in a corporation still come back **1.5×** as often (`robustness_equal_activity.csv`). For players who were already committed it makes no difference: belonging matters most for the newcomers who haven't decided yet.
- **This is a link, not proof.** Player-space numbers are partly visibility: players there fly in fleets and show up more.
- **When the group falls, its newcomers leave** (`horde_collapse.csv`). Pandemic Horde took in more newcomers than any other alliance (8,203). It lost almost all its space in November–December 2025. Before that, its newcomers stayed slightly more often than other alliances' (22% vs 20% at month 3); those who joined from August to November 2025 stayed less (17% vs 23%), and the November cohort only 8% vs 22%. Its existing members left a little more too, so it's one case and not proof, but it points the same way.
- **History agrees** (Groen, *Empires of Eve*): veterans have hunted newcomers since 2003, and what worked was belonging with support. TEST grew from a Reddit group to 3,000+ members with a place to learn, free starter ships and ship replacement (Vol. 2, chs. North and South; A Couch in Deklein).

### 4. What it's worth: buying newcomers vs keeping them
Estimates from CCP's audited accounts; shade them as estimates (`unit_economics.csv`, `newcomer_value.csv`, `revenue_quarterly.csv`).
- **Revenue:** ARR (subscription and in-game sales) grew from **$55.0M to $60.8M** in 2025; MRR from $4.6M to **$5.1M**.
- **Buying newcomers got more expensive:** CCP raised marketing **41%** ($11.4M → $16.1M) in 2025, yet signups fell 10%. CAC rose from $10.43 to **$16.25 per signup**, **$117 per engaged newcomer**, and **$1,424 per newcomer still playing a year later**.
- **Most newcomers don't pay back their cost in their first year.** At about **$43 of revenue per active player per month** (ARPU), first-year value (LTV) is:

| Newcomer | Active months in first year | First-year value | vs cost to acquire ($117) |
|---|---|---|---|
| Casual, in the starter corporation | 1.7 | $72 | **0.6×** |
| Average newcomer | 2.4 | $102 | 0.9× |
| Joined a corporation and got a kill | 3.0 | $127 | **1.1×** |

- **Keeping is cheaper than buying.** Each 10% of engaged newcomers who join a group and get a win instead of playing alone adds about **$0.64M** in first-year revenue (13,700 players × $47). CCP's extra $4.7M of marketing in 2025 came with 104,000 fewer signups.
- **Launches bring people, not stayers:** expansion-month newcomers stay no longer than others (14% vs 15% at month 3), though expansions do bring old players back: Catalyst (November 2025) brought back **23,311** (`funnel_monthly.csv`, `returners_monthly.csv`).

### 5. Recommendation
- View: what-if slider, "% of newcomers moved into a group" → extra first-year revenue (`whatif_inputs.csv`).
- **Protect and group newcomers in their first week.** Move them from the starter corporation into a mid-sized player corporation, and give them a first fight they can win. The game already has a corporation finder and teaching corporations such as EVE University; the tutorial could end there instead of in solo missions.
- **Spend on keeping, not only on buying:** a newcomer who joins a group pays back their acquisition cost in the first year; one who plays alone covers about 60%.
- **Test it before rolling it out:** an A/B test on placing new players in corporations would turn our strongest lead into proof, and measure its revenue directly.
- **Open question:** since the sale to its management (6 May 2026), signups rose 13% but active players barely changed (`sale_before_after.csv`). More people are trying EVE; will the new owners help them through their first week?

## Caveats (one slide, plain words)
- **We see 13% of new characters in detail:** those who fight or trade. Signups, players online and revenue cover everyone.
- **"Casual" means seen on one day,** not played on one day. Some casual newcomers play quietly and only appear when killed.
- **Activity, not logins.** A player who stops fighting and trading looks like they quit. DAU / MAU counts visible players only (16,000 a day, against 24,000 online at any moment).
- **A link, not proof.** Keen players may join groups more often; our checks reduce but don't remove this.
- **Money figures are estimates.** ARPU puts all revenue on visible players, and newcomers pay less than veterans, so first-year values are upper bounds; marketing covers all of CCP, not only new EVE players. The comparison between groups is the point, not the exact dollars.
- **Characters, not people.** One account can have up to three characters, and a player can have several accounts.
- **Comparisons with other games use different measures**; read them as a sense of scale.

## Dashboard rules
- One headline per page, written as the finding.
- No game jargon without the glossary.
- The same event markers on every time chart (`events.csv`).
- Estimates (money per player, KRW converted to USD) shaded differently from official figures.

## Path B (kept for later)
The broader version of acts 2–3: all new players instead of casuals. "What the stayers have in common": joined a corporation and got a kill (24% at month 3 vs 9%), fought in a 100+ pilot battle (27%), mid-sized corporations (23%), with the robustness checks (`retention_by_segment.csv`, `robustness_contracts_only.csv`, `robustness_equal_activity.csv`). The effect is 1.4–2× overall and disappears for already-committed players, which is why the casual focus is the main path.
