# What makes new EVE players stay?

**For:** CCP Games (now Fenris Creations), the team that runs EVE Online's subscriptions.

**Answer:** belonging. New players who join a player corporation in their first month stay **1.4 to 2 times as often** as those who play alone, and are about **twice as likely to pay**. The difference is biggest for casual newcomers. We can show the link, not prove the cause.

All numbers come from `data/exports/` (built by `db/analysis.sql` and `scripts/export.sh`).

## Words the audience needs (one box on page 0)
- **Corporation:** a player-run group, like a guild or a company. **Alliance:** a group of corporations.
- **ISK:** the in-game money. **PLEX:** an item bought with real money and sold to other players for ISK.
- **Alpha / Omega:** free account / paid subscription. Some ships can only be flown with Omega.
- **High-sec / null-sec:** safe space policed by the game / lawless space held by player alliances.

## The story (one dashboard page each)

### 0. What is EVE Online?
One shared universe where everything is made, traded, fought over and destroyed by players.
- **Wars:** about **16,000 ships destroyed every day**, and **13,983 battles with 100+ pilots** since January 2024. The largest: **4,367 pilots in one hour** (4-HWWF, April 2026).
- **Economy:** players produce about **177 trillion ISK** of goods a month and destroy about **70 trillion**. The money supply grew from 2.1 to 2.95 quadrillion ISK.
- **Culture:** **104,786 player corporations** and **3,788 alliances** took part in fights; about **24,000 players are online at any moment**.
- Views:
  - **War-zone map by month:** CCP's map of 5,485 systems, with dots sized by the largest battle and coloured by area (`map_systems.csv`, `map_links.csv`, `war_zones_monthly.csv`). Animate it by month.
  - **Economy by month:** value produced, destroyed and mined, by area, as in CCP's Monthly Economic Report (`economy_monthly.csv`), plus money created vs removed (`isk_monthly.csv`).
  - **Headline numbers:** `eve_at_a_glance.csv`.

### 1. The challenge: EVE keeps its veterans, not its newcomers
- **EVE is a niche game.** At its peak it had **500,000 subscribers** (2013), against 12 million for World of Warcraft, 1.7 million for Star Wars: The Old Republic and 420,000 for EverQuest.
- **But its players stay.** On Steam, EVE still had **84%** of its peak-month players a year later. Big recent launches kept far fewer: New World 8.5%, Throne and Liberty 9%, Lost Ark 24%.
- **Newcomers are the problem.** **2.73 million** characters were created from January 2024 to August 2026. Only **13%** ever fought or traded with another player, and of those **8.2%** were still playing a year later, about **1 in 100** of everyone who signed up. CCP's own figure (2019): 9 in 10 new players quit in the first week.
- That is in line with other online games: free-to-play MMOs keep about 6% of new players for a year.
- Views:
  - **Comparison:** peak subscribers, and the share of players kept a year after the peak (`mmo_comparison.csv`).
  - **Funnel:** signups → engaged → still playing (`funnel_monthly.csv`, `kpi_tiles.csv`).

### 2. What makes them stay: belonging
Share of new players still playing 3 months after their first month (`retention_by_segment.csv`):

| First month | Still playing at month 3 |
|---|---|
| No corporation, no kill | 9% |
| All new players | 15% |
| In a corporation of 201–1,000 members | 23% |
| Joined a corporation and got a kill | 24% |
| Fought in a battle of 100+ pilots | 27% |

- **Main chart:** these groups over 12 months.
- **Size matters:** mid-sized corporations (201–1,000 members) keep new players best. Tiny ones are barely better than none.
- **Dying doesn't drive players away:** almost everyone loses a ship (88%).
- **Is it just that keen players join corporations?** We checked three ways (`robustness_contracts_only.csv`, `robustness_equal_activity.csv`):
  - Counting only trading activity, which fleets can't inflate: corporation members still stay **1.4×** as often.
  - Comparing players who were equally active in their first month: still **1.5–1.6×**.
  - With both together, the effect remains for **casual newcomers** (1.5×) but disappears for players who were already playing a lot.
  - So: belonging matters most for the newcomers who haven't committed yet. We show a strong link, not proof of cause.

### 3. What doesn't work: launches bring people, not stayers
- Big expansions bring a rush of signups, but those players don't stay longer: **14%** still playing at month 3 for expansion-month newcomers, against **15%** in other months (`funnel_monthly.csv`).
- Equinox (June 2024) brought the most signups of the window (115,029) and the weakest retention of 2024 (12.7%).
- Expansions do bring **old players back**: Catalyst (November 2025) brought back **23,311** players who had left, the most of any month (`returners_monthly.csv`).
- View: signups (bars), 3-month retention (line), returners, with expansion markers (`events.csv`).

### 4. What it's worth: players who belong also pay
- **Belonging turns players into payers.** Within a year, **35%** of new players who joined a corporation and got a kill flew a ship that needs a paid subscription, against **14%** of those who did neither. In mid-sized corporations, **44%** (`conversion_by_segment.csv`).
- **Revenue grew while signups fell.** CCP's subscription and in-game revenue rose **11%** in 2025 ($55.0M → $60.8M) while signups fell 10% (`ccp_annual.csv`). Pearl Abyss's quarterly figures match CCP's audited accounts within 0.5% (`revenue_quarterly.csv`).
- **Retention of new players improved** from 14.0% (2024) to 16.2% (July 2025 – May 2026) at month 3. It started rising in spring 2025, before the July 2025 price change, so we don't credit the price change alone (`omega_prices.csv`).
- **Estimate (shade it as an estimate):** about 47,500 visible new players a year start without a corporation. If they all joined one, about **1,000 to 2,100 more** would still be playing a year later. On a 12-month Omega plan ($144) that is **$0.15M to $0.30M a year**, under 1% of revenue. The visible players are only 13% of signups, so this is a floor.

### 5. So what
- **Recommendation:** put new players into groups early. Move them out of the starter corporation into **mid-sized player corporations** in their first month, with beginner fleets and a first fight. They are **1.4 to 2 times as likely to stay** and about **twice as likely to pay**. Use expansions to win back players who left.
- **Open question:** Pearl Abyss sold CCP to its management on 6 May 2026. In the three months after, signups rose 13% but players online and active players barely changed (`sale_before_after.csv`). More people are trying EVE; will the new owners help them find a group?

## Supporting: satisfaction
- Steam reviews stay between 63% and 74% positive. The July 2025 price change got people talking on the forums but didn't change satisfaction (`signals_monthly.csv`).

## Caveats (one slide, plain words)
- **We see 13% of new characters in detail:** those who fight or trade with others. Signups, players online and revenue cover everyone.
- **Activity, not logins.** A player who stops fighting and trading looks like they quit.
- **A link, not proof.** Keen players may join corporations more often; our checks reduce but don't remove this.
- **Characters, not people.** One account can have several characters.
- **Paying is inferred** from flying a ship that needs a subscription.
- **Comparisons with other games use different measures** (subscribers, Steam players, logins); read them as a sense of scale.

## Dashboard rules
- One headline per page, written as the finding.
- No game jargon without the glossary; say "players", "groups", "paid subscription".
- The same event markers on every time chart (`events.csv`).
- Estimates (KRW converted to USD, the value estimate) shaded differently from official figures.
