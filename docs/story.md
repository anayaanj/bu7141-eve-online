# Why EVE loses its newcomers

**For:** CCP Games (now Fenris Creations), the team that runs EVE Online's subscriptions.

**Question:** EVE keeps its veterans like few games do, but loses almost every newcomer. Why, and what could keep them?

**Answer:** most newcomers we can see show up on a single day, and for most of them that day is being killed by a veteran, alone, in the starter areas. The few who come back were in a player group, in player-held space, or got a win. Getting newcomers into groups in their first week is the strongest lead, and worth testing.

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
- **History:** player alliances have fought wars over territory since 2003, with spies, betrayals and coalitions that act like nations. The Great War ended in 2009 with 30,000+ of about 300,000 players taking part; the Bloodbath of B-R5RB (2014) destroyed the equivalent of over US$300,000 in ships (`data/reference/great_wars.csv`, from Groen, *Empires of Eve*, Vols. 1 and 2).
- **Wars:** about **16,000 ships destroyed every day**, and **13,983 battles with 100+ pilots** since January 2024. The largest: **4,367 pilots in one hour** at 4-HWWF (April 2026), where Fraternity held its system.
- **Empires rise and fall:** Pandemic Horde held 414 systems in November 2025, 59 a month later and none by April 2026. Goonswarm grew from 117 systems (January 2024) to 509, the largest empire on the map (`sovereignty_alliances_monthly.csv`).
- **Economy:** players produce about **177 trillion ISK** of goods a month and destroy about **70 trillion**.
- **Culture:** **104,786 player corporations** and **3,788 alliances** took part in fights; about **24,000 players are online at any moment**.
- Views:
  - **History timeline:** 25 turning points from launch (2003) to the Pearl Abyss purchase (2018), as a strip along the top (`great_wars.csv`).
  - **Who holds space, by month:** the alliance holding each system, coloured by alliance, animated like the community's daily sovereignty maps (`sovereignty_monthly.csv` with `map_systems.csv`). Visual reference: Verite Rendition's influence maps (verite.space).
  - **War-zone map by month:** CCP's map of 5,485 systems, with dots sized by the largest battle (`map_systems.csv`, `map_links.csv`, `war_zones_monthly.csv`). Animate it by month.
  - **Economy by month:** value produced, destroyed and mined, by area, as in CCP's Monthly Economic Report (`economy_monthly.csv`, `isk_monthly.csv`).
  - **Headline numbers:** `eve_at_a_glance.csv`.

### 1. The paradox: loyal veterans, vanishing newcomers
- **EVE is niche:** at its peak it had **500,000 subscribers** (2013), against 12 million for World of Warcraft.
- **Its players stay:** on Steam, EVE kept **84%** of its peak-month players a year later. Big recent launches kept 8–24% (New World, Throne and Liberty, Lost Ark).
- **Its newcomers don't:** **2.73 million** characters were created from January 2024 to August 2026. Only **13%** ever fought or traded with another player, and **8.2%** of those were still playing a year later, about **1 in 100** signups. CCP's own figure (2019): 9 in 10 new players quit in the first week.
- **Veterans still carry the game:** in August 2026, pre-2024 characters were still 64% of active players and landed 80% of kills.
- Views: comparison with other MMOs (`mmo_comparison.csv`); funnel from signup to still playing (`funnel_monthly.csv`, `kpi_tiles.csv`).

### 2. A newcomer's first day
- **Most newcomers are seen on a single day.** **62%** of the new players we can see appear on just one day in their first month. Only **9.5%** of them are seen again 3 months later, against **45%** of those seen on 8+ days (`first_month_active_days.csv`).
- **For most, that day is a death** (`casual_first_day.csv`):
  - **67%** were killed by another player, 11% by the computer.
  - **88%** of those killed by a player were finished off by a **veteran**.
  - **34%** were killed within **a week of creating their character**.
  - **58%** were in high-sec or low-sec, and **37%** were still in the starter corporation. Only 0.15% were killed by a player in a starter system: they are safe at home and die once they head out alone.
- **The game prepares them for something else.** The official tutorial and career missions are solo and teach fighting the computer, with little training for fighting players (EVE University wiki, *Getting Started in EVE Online*). Most newcomers we see die to players.
- Views: what happened on the one day (bar), who killed them (veteran vs newer player), where (map of casual deaths).

### 3. The few who come back
Casual newcomers still seen 3 months later (`casual_first_day.csv`):

| On their one day they were… | Seen again at month 3 |
|---|---|
| In the starter corporation | 6.9% |
| In a mid-sized player corporation (51–1,000) | **13.7–15.0%** |
| In high-sec | 6.3% |
| In player-held null-sec | **14.4%** |
| Killed by another player | 8.5% |
| Got a kill and survived | **17.3%** |

- **They were in a group, in player space, or got a win.** Each roughly doubles the chance of being seen again.
- **It holds under our strictest test.** Counting only trading activity, and comparing players who were equally active, casual newcomers in a corporation still come back **1.5×** as often (`robustness_equal_activity.csv`). For players who were already committed it makes no difference: belonging matters most for the newcomers who haven't decided yet.
- **This is a link, not proof.** Player-space numbers are partly visibility: players there fly in fleets and show up more.
- **History agrees** (Groen, *Empires of Eve*):
  - Veterans have hunted newcomers since 2003; in 2009–10 one major alliance spent its income mostly on killing new players in policed space (Vol. 2, ch. King Karttoon).
  - What worked was belonging with support: the coalition that won the Great War grew by teaching beginners others refused (Vol. 1, pp. 161-165), and TEST grew from a Reddit group to 3,000+ members with a place to learn, free starter ships and ship replacement (Vol. 2, chs. North and South; A Couch in Deklein).

### 4. What doesn't fix it, and what it's worth
- **Launches bring people, not stayers:** expansion-month newcomers stay no longer than others (14% vs 15% at month 3). Expansions do bring old players back: Catalyst (November 2025) brought back **23,311** (`funnel_monthly.csv`, `returners_monthly.csv`).
- **Players who belong also pay:** within a year, **35%** of new players who joined a corporation and got a kill flew a ship that needs a paid subscription, against **14%** of those who did neither (`conversion_by_segment.csv`).
- **Revenue grew while signups fell:** subscription and in-game revenue rose **11%** in 2025 ($55.0M → $60.8M) while signups fell 10% (`ccp_annual.csv`). Keeping more newcomers is the growth that's left.

### 5. Recommendation
- **Protect and group newcomers in their first week.** Move them from the starter corporation into a mid-sized player corporation, and give them a first fight they can win. The game already has a corporation finder and teaching corporations such as EVE University; the tutorial could end there instead of in solo missions.
- **Test it before rolling it out:** an A/B test on placing new players in corporations would turn our strongest lead into proof.
- **Open question:** since the sale to its management (6 May 2026), signups rose 13% but active players barely changed (`sale_before_after.csv`). More people are trying EVE; will the new owners help them through their first week?

## Caveats (one slide, plain words)
- **We see 13% of new characters in detail:** those who fight or trade. Signups, players online and revenue cover everyone.
- **"Casual" means seen on one day,** not played on one day. Some casuals play quietly and only appear when killed.
- **Activity, not logins.** A player who stops fighting and trading looks like they quit.
- **A link, not proof.** Keen players may join groups more often; our checks reduce but don't remove this.
- **Characters, not people.** One account can have up to three characters, and a player can have several accounts.
- **Comparisons with other games use different measures**; read them as a sense of scale.

## Dashboard rules
- One headline per page, written as the finding.
- No game jargon without the glossary.
- The same event markers on every time chart (`events.csv`).
- Estimates (KRW converted to USD) shaded differently from official figures.

## Path B (kept for later)
The broader version of acts 2–3: all new players instead of casuals. "What the stayers have in common": joined a corporation and got a kill (24% at month 3 vs 9%), fought in a 100+ pilot battle (27%), mid-sized corporations (23%), with the robustness checks (`retention_by_segment.csv`, `robustness_contracts_only.csv`, `robustness_equal_activity.csv`). The effect is 1.4–2× overall and disappears for already-committed players, which is why the casual focus is the main path.
