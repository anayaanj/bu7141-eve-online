# The Friendship Machine

**Question:** What turns a new EVE character into a player who stays?

**Answer:** belonging. New players who join a player corporation, get their first kill, or fight in a big battle in their first month are about twice as likely to still be playing three months later. Dying hardly matters: almost everyone loses a ship.

> "…the foundation of the Friendship Machine, as we call it." CCP's CEO, in *EVE Online | Down the Rabbit Hole* (Fredrik Knudsen, 00:30:37)

All numbers below come from `data/exports/` (built by `db/analysis.sql` and `scripts/export.sh`). Definitions are at the top of `db/analysis.sql`.

## The narrative (one dashboard page each)

### 1. The challenge: most new characters never stick
- **2,733,207** characters were created between Jan 2024 and Aug 2026 (exact, from CCP's ID sequence).
- Only **13.1%** (356,769) ever fight or trade with another player.
- Of those, **14.9%** are still active 3 months later and **8.2%** after 12 months.
- Hook: that is exactly World of Warcraft's rate at its 2006–07 peak (**8.2%** at 12 months, measured the same way). The "harshest MMO" keeps new players as well as the friendliest one.
- Views: KPI tiles (`kpi_tiles.csv`), the monthly funnel (`funnel_monthly.csv`), cohort heatmap (`cohort_heatmap.csv`).

### 2. The answer: belonging (main chart)
Share still active 3 months after their first month (`retention_by_segment.csv`):

| First month | Month 3 | Month 12 |
|---|---|---|
| Fought in a war (100+ pilots) | **27.5%** | 16.1% |
| Fought in a skirmish (50–99) | 25.7% | 12.9% |
| Joined a corp and got a kill | **24.2%** | 12.1% |
| Got a kill only | 15.4% | 9.9% |
| Joined a corp only | 15.0% | 8.7% |
| All new players | 14.9% | 8.2% |
| Neither | **9.1%** | 5.0% |
| Lost a ship / did not | 14.6% / 17.4% | 8.0% / 9.8% |

- Main chart: retention curves (k = 0–12) for "Neither", "Joined a corp and got a kill", "Fought in a war", with World of Warcraft as a reference line.
- **It holds after a year:** at month 12 the advantage over "Neither" (5.0%) is 2.4× for corp + kill (12.1%) and 3.2× for war veterans (16.1%; 10,210 players with a full year of follow-up).
- **It's belonging, not combat.** Non-combatants (contracts only, no killmails) stay at 12.1% at month 3, the same as players who only got killed (12.2%) and about half the rate of players who fought back (22.6%). Within every group, a player corporation adds ~60%: non-combatants 9.9% → 15.4%, victims 9.0% → 15.0%, kill-getters 15.4% → 24.2%. A non-combatant in a corp stays exactly as often as a fighter with a kill but no corp (15.4%). (Caveat: free accounts can only use contracts in a limited way, per CCP's store.)
- **The effect happens early:** of players still active at month 3, about half are still active at month 12 in every segment (50–59%). Belonging gets new players over the first hump; after that, every group fades at a similar pace.
- Line: *"The best way to recruit people is by shooting them."* (an early mercenary leader, Down the Rabbit Hole, 00:44:55)

### 3. What doesn't work: launches bring people, not stayers
- Expansion months spike signups, but those cohorts don't stay longer (`funnel_monthly.csv`).
- **Equinox (June 2024): 115,029 signups, the biggest month, and the lowest 3-month retention of 2024 (12.7%).** Revenant and Legion: average retention.
- Twitch, Google Trends and Steam players (`signals_monthly.csv`) rise around launches, which is attention, not loyalty.
- View: signups (bars) with 3-month retention (line) and event markers (`events.csv`).

### 4. What it's worth: fewer arrive, more stay, more revenue
- After the July 2025 Omega restructure (cheaper long plans plus free PLEX, `omega_prices.csv`), signups fell but **3-month retention of new cohorts rose from 14.0% (2024 cohorts) to 16.2% (Jul 2025 – May 2026 cohorts)**, about 16% higher (monthly range 12.7–15.5% vs 14.0–18.3%).
- **But be careful with cause:** 12-month retention started rising in **April 2025**, before the restructure (Apr–Jun 2025 cohorts: 9.4–9.5% vs ~8% for 2024; Jul–Aug 2025: 8.6–9.6%; later cohorts don't have a year of follow-up yet). Say: retention has been improving since spring 2025 (around the Legion expansion); the restructure fits the trend but isn't the only cause.
- CCP's **subscription and in-game revenue rose 11% in 2025 ($55.0M → $60.8M)** while signups fell 10% (`ccp_annual.csv`).
- EVE revenue by quarter from Pearl Abyss, converted to USD (`revenue_quarterly.csv`), matches CCP's audited game revenue within 0.5% for 2023–2025.
- PLEX fell from ~6.2M ISK (Q2 2025) to ~4.5M after PLEX moved to a single global market in July 2025 (`plex_monthly.csv`).
- Players who flew an Omega-only (paid) ship in their first month: **26.2%** active at month 3 vs 13.0%.

### 5. So what
- **Recommendation:** for a subscription game, onboarding new players into groups is worth more than launch spikes. Corporation recruitment, beginner fleets and first fights in week one roughly double retention.
- **Open question:** Pearl Abyss sold CCP (completed 6 May 2026). Signups rose (85K in May, 90K in June), Twitch peaked, and Cradle of War launched in June. Will the new owners lean into the Friendship Machine?

## Satisfaction (supporting, not a claim)
- Steam reviews stay at 63–74% positive; the restructure quarter (Q3 2025) was 65.6%, then 71.8–71.9%. New players (under 50 h) are 5–8 points less positive.
- Forum threads spike at events: pricing after July 2025, ownership in May 2026, new players in April 2026 ("Separate Space for Newbies?").
- So the restructure got people talking without changing satisfaction. Act 4 rests on retention and revenue, not sentiment.

## Caveats (say them on the slides)
- **Correlation, not causation.** Players who join corps may be more committed to begin with.
- **We see the 13% who are visible** (killmails and contracts). Miners and market-only traders stay invisible, so retention is a lower bound.
- **Characters, not accounts.** One account can hold several characters.
- **The latest cohorts are censored:** retention at month k only counts cohorts with k months of follow-up.

## Dashboard rules
- One headline per page, written as the finding.
- The same event markers on every time chart (`events.csv`).
- Estimates (USD from KRW, ARPU) are shaded differently from official figures.
- Business language: subscribers, cohorts, retention, not killmails.
