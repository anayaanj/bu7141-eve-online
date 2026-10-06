-- Analysis layer for the story "What turns a new EVE character into a player who stays?"
-- Run after scripts/load.sh:  docker compose exec -T db psql -U eve -d eve -f - < db/analysis.sql
-- Definitions (used by every export):
--   new player   = character created from 2024-01-01 (ID >= first boundary), seen in killmails or contracts
--   first month  = first month with any killmail or contract (the "cohort")
--   active in k  = has activity in first_month + k months
--   retention k  = share of a cohort active in month k; only cohorts with k months of follow-up count

DROP SCHEMA IF EXISTS analysis CASCADE;
CREATE SCHEMA analysis;

CREATE TABLE analysis.new_player AS
WITH first AS (
  SELECT a.character_id, min(a.month) AS first_month
  FROM character_month_activity a
  WHERE a.character_id >= (SELECT min(first_character_id) FROM character_signup_month)
  GROUP BY 1
),
battles AS (  -- biggest battle each new player fought in during their first month
  SELECT f.character_id, max(b.battle_class) AS first_month_battle
  FROM first f
  JOIN killmail_participant p ON p.character_id = f.character_id
  JOIN killmail k ON k.killmail_id = p.killmail_id
   AND k.kill_date >= f.first_month AND k.kill_date < f.first_month + interval '1 month'
  JOIN battle b ON b.battle_id = k.battle_id
  GROUP BY 1
)
SELECT f.character_id,
       f.first_month,
       a.in_player_corporation AS joined_corp,
       a.kills > 0             AS got_kill,
       a.losses > 0            AS lost_ship,
       a.contracts_issued > 0  AS traded,
       a.flew_omega_ship       AS flew_omega,
       coalesce(bt.first_month_battle, 'none') AS first_month_battle
FROM first f
JOIN character_month_activity a ON a.character_id = f.character_id AND a.month = f.first_month
LEFT JOIN battles bt ON bt.character_id = f.character_id;

ALTER TABLE analysis.new_player ADD PRIMARY KEY (character_id);

-- First-month context from killmails: corporation size, main area, and the month of the first Omega-only ship
CREATE TABLE analysis.new_player_context AS
WITH fm AS (
  SELECT n.character_id, p.corporation_id, k.killmail_time, s.security_band
  FROM analysis.new_player n
  JOIN killmail_participant p ON p.character_id = n.character_id
  JOIN killmail k ON k.killmail_id = p.killmail_id
   AND k.kill_date >= n.first_month AND k.kill_date < n.first_month + interval '1 month'
  JOIN solar_system s ON s.solar_system_id = k.solar_system_id
),
last_corp AS (  -- corporation on the last killmail of the first month
  SELECT DISTINCT ON (character_id) character_id, corporation_id FROM fm ORDER BY character_id, killmail_time DESC
),
area AS (SELECT character_id, mode() WITHIN GROUP (ORDER BY security_band) AS main_area FROM fm GROUP BY 1)
SELECT n.character_id,
       CASE WHEN lc.character_id IS NULL THEN NULL      -- contracts only: no killmail to read the corporation from
            WHEN c.is_npc THEN 'NPC starter corp'
            WHEN c.member_count <= 10 THEN '2-10 members'
            WHEN c.member_count <= 50 THEN '11-50 members'
            WHEN c.member_count <= 200 THEN '51-200 members'
            WHEN c.member_count <= 1000 THEN '201-1,000 members'
            WHEN c.member_count > 1000 THEN '1,000+ members' END AS first_corp_size,  -- member_count is today's, not at joining
       ar.main_area,
       date_trunc('month', pc.first_omega_seen)::date AS first_omega_month
FROM analysis.new_player n
JOIN player_character pc USING (character_id)
LEFT JOIN last_corp lc USING (character_id)
LEFT JOIN corporation c ON c.corporation_id = lc.corporation_id
LEFT JOIN area ar USING (character_id);

ALTER TABLE analysis.new_player_context ADD PRIMARY KEY (character_id);

-- Months since first month in which each new player was active (k = 0..32)
CREATE TABLE analysis.new_player_activity AS
SELECT n.character_id, n.first_month,
       (extract(year FROM age(a.month, n.first_month)) * 12 + extract(month FROM age(a.month, n.first_month)))::int AS k
FROM analysis.new_player n
JOIN character_month_activity a ON a.character_id = n.character_id;

CREATE INDEX ON analysis.new_player_activity (character_id, k);

-- Segment labels used across the dashboard
CREATE VIEW analysis.new_player_segment AS
SELECT character_id, first_month, 'All new players' AS segment FROM analysis.new_player
UNION ALL SELECT character_id, first_month, CASE WHEN joined_corp AND got_kill THEN 'Joined a corp and got a kill'
                                               WHEN joined_corp THEN 'Joined a corp only'
                                               WHEN got_kill THEN 'Got a kill only'
                                               ELSE 'Neither' END FROM analysis.new_player
UNION ALL SELECT character_id, first_month, CASE first_month_battle WHEN 'war' THEN 'Fought in a war (100+ pilots)'
                                                                   WHEN 'skirmish' THEN 'Fought in a skirmish (50-99)'
                                                                   ELSE 'No battle' END FROM analysis.new_player
UNION ALL SELECT character_id, first_month, CASE WHEN lost_ship THEN 'Lost a ship' ELSE 'Did not lose a ship' END FROM analysis.new_player
UNION ALL SELECT character_id, first_month, CASE WHEN flew_omega THEN 'Flew an Omega-only ship' ELSE 'No Omega-only ship' END FROM analysis.new_player
UNION ALL SELECT character_id, first_month,
       CASE WHEN traded AND NOT (got_kill OR lost_ship) THEN 'Non-combatant (contracts only)'
            WHEN traded THEN 'Traded and fought'
            WHEN got_kill THEN 'Combat, got a kill'
            ELSE 'Combat, victim only' END FROM analysis.new_player
UNION ALL SELECT character_id, first_month,
       CASE WHEN traded AND NOT (got_kill OR lost_ship) THEN 'Non-combatant'
            WHEN got_kill THEN 'Got a kill' ELSE 'Victim only' END
       || CASE WHEN joined_corp THEN ', in a corp' ELSE ', no corp' END FROM analysis.new_player
UNION ALL SELECT character_id, first_month, 'Corp size: ' || first_corp_size
          FROM analysis.new_player JOIN analysis.new_player_context USING (character_id) WHERE first_corp_size IS NOT NULL;

-- Retention by segment and month k, censored: a cohort only counts for k if first_month + k <= 2026-08-01
CREATE VIEW analysis.retention_by_segment AS
SELECT s.segment, k.k,
       count(*) AS players,
       count(act.character_id) AS active,
       round(count(act.character_id)::numeric / count(*), 4) AS retention
FROM analysis.new_player_segment s
CROSS JOIN generate_series(0, 12) AS k(k)
LEFT JOIN analysis.new_player_activity act ON act.character_id = s.character_id AND act.k = k.k
WHERE s.first_month + make_interval(months => k.k) <= date '2026-08-01'
GROUP BY s.segment, k.k;

-- Payer conversion: share of new players seen in an Omega-only (paid) ship by their first month and within 12 months.
-- Only cohorts with 12 months of follow-up (first month <= 2025-08-01).
CREATE VIEW analysis.conversion_by_segment AS
WITH seg AS (
  SELECT s.segment, s.first_month, x.first_omega_month
  FROM analysis.new_player_segment s JOIN analysis.new_player_context x USING (character_id)
  UNION ALL
  SELECT 'Area: ' || x.main_area, n.first_month, x.first_omega_month
  FROM analysis.new_player n JOIN analysis.new_player_context x USING (character_id)
  WHERE x.main_area IN ('High Sec', 'Low Sec', 'Null Sec (Sov)', 'Null Sec (NPC)', 'Wormhole')
)
SELECT segment, count(*) AS players,
       round(avg(coalesce(first_omega_month <= first_month, false)::int), 4) AS converted_month_1,
       round(avg(coalesce(first_omega_month <= first_month + interval '12 month', false)::int), 4) AS converted_within_12_months
FROM seg WHERE first_month <= date '2025-08-01'
GROUP BY segment;

-- Returners: characters active in a month after 3+ inactive months, having been active earlier in the window.
-- Counts before ~Oct 2024 are low because the window starts in Jan 2024 (not enough history to spot a return).
CREATE TABLE analysis.returners_monthly AS
WITH a AS (
  SELECT month, lag(month) OVER (PARTITION BY character_id ORDER BY month) AS previous_month
  FROM character_month_activity
)
SELECT month,
       count(*) FILTER (WHERE previous_month <= month - interval '4 month') AS returners,
       count(*) AS active,
       round(count(*) FILTER (WHERE previous_month <= month - interval '4 month')::numeric / count(*), 4) AS returner_share
FROM a WHERE month >= date '2024-05-01' GROUP BY month;

-- Robustness: is the corporation effect just visibility? Corp members fly in fleets and appear in more killmails,
-- so here "active" counts contracts only, among new players who already traded in their first month.
CREATE VIEW analysis.robustness_contracts_only AS
SELECT CASE WHEN n.joined_corp THEN 'Traded in month 1, in a corp' ELSE 'Traded in month 1, no corp' END AS segment,
       k.k,
       count(*) AS players,
       count(c.character_id) AS active_contracts,
       round(count(c.character_id)::numeric / count(*), 4) AS retention_contracts_only,
       round(count(a.character_id)::numeric / count(*), 4) AS retention_any_activity
FROM analysis.new_player n
CROSS JOIN (VALUES (3), (12)) AS k(k)
LEFT JOIN character_month_activity c ON c.character_id = n.character_id
     AND c.month = n.first_month + make_interval(months => k.k) AND c.contracts_issued > 0
LEFT JOIN analysis.new_player_activity a ON a.character_id = n.character_id AND a.k = k.k
WHERE n.traded AND n.first_month + make_interval(months => k.k) <= date '2026-08-01'
GROUP BY 1, 2;

-- Battle size at its busiest hour. A few battles chain separate fights in a busy system over days
-- (killmails within an hour of each other), so "largest battle" uses distinct pilots in the peak hour.
CREATE TABLE analysis.battle_peak AS
SELECT battle_id, max(pilots) AS peak_hour_pilots
FROM (
  SELECT k.battle_id, date_trunc('hour', k.killmail_time) AS hour, count(DISTINCT p.character_id) AS pilots
  FROM killmail k JOIN killmail_participant p USING (killmail_id)
  WHERE k.battle_id IS NOT NULL
  GROUP BY 1, 2
) h GROUP BY battle_id;

ALTER TABLE analysis.battle_peak ADD PRIMARY KEY (battle_id);

-- Robustness: are corp members just keener? Compare players equally active in their first month (active days),
-- on any activity and, for players who traded in month 1, on contracts only.
CREATE VIEW analysis.robustness_equal_activity AS
SELECT CASE WHEN a.active_days = 1 THEN '1 day' WHEN a.active_days <= 3 THEN '2-3 days' ELSE '4+ days' END AS first_month_active_days,
       CASE WHEN n.joined_corp THEN 'In a corp' ELSE 'No corp' END AS corp,
       count(*) AS players,
       round(count(a3.character_id)::numeric / count(*), 4) AS retention_month_3_any_activity,
       count(*) FILTER (WHERE n.traded) AS traders,
       round(count(c3.character_id) FILTER (WHERE n.traded)::numeric / nullif(count(*) FILTER (WHERE n.traded), 0), 4)
         AS retention_month_3_contracts_only_traders
FROM analysis.new_player n
JOIN character_month_activity a ON a.character_id = n.character_id AND a.month = n.first_month
LEFT JOIN analysis.new_player_activity a3 ON a3.character_id = n.character_id AND a3.k = 3
LEFT JOIN character_month_activity c3 ON c3.character_id = n.character_id
     AND c3.month = n.first_month + interval '3 month' AND c3.contracts_issued > 0
WHERE n.first_month <= date '2026-05-01'
GROUP BY 1, 2;

-- Casual new players: seen on only one day in their first month (62% of new players). What their one visible day looked like.
-- "Veteran" = character created before 2024 (ID below the first 2024 boundary).
CREATE TABLE analysis.casual_player AS
WITH c AS (
  SELECT n.character_id, n.first_month, n.got_kill, n.lost_ship, n.traded, x.main_area, x.first_corp_size
  FROM analysis.new_player n
  JOIN character_month_activity a ON a.character_id = n.character_id AND a.month = n.first_month
  JOIN analysis.new_player_context x ON x.character_id = n.character_id
  WHERE a.active_days = 1
),
deaths AS (  -- each casual's first-month deaths
  SELECT c.character_id, k.kill_date, s.security_band, g.group_name AS ship_group,
         fb.character_id AS killer_id,
         EXISTS (SELECT 1 FROM killmail_participant at WHERE at.killmail_id = k.killmail_id
                 AND at.role = 'attacker' AND at.character_id IS NOT NULL) AS by_player
  FROM c
  JOIN killmail_participant v ON v.character_id = c.character_id AND v.role = 'victim'
  JOIN killmail k ON k.killmail_id = v.killmail_id
   AND k.kill_date >= c.first_month AND k.kill_date < c.first_month + interval '1 month'
  JOIN solar_system s ON s.solar_system_id = k.solar_system_id
  LEFT JOIN item_type t ON t.type_id = v.ship_type_id
  LEFT JOIN item_group g ON g.group_id = t.group_id
  LEFT JOIN killmail_participant fb ON fb.killmail_id = k.killmail_id AND fb.role = 'attacker' AND fb.final_blow
)
SELECT c.character_id, c.first_month, c.main_area, c.first_corp_size, c.got_kill, c.traded,
       bool_or(d.by_player) IS TRUE AS killed_by_player,
       bool_or(NOT d.by_player) IS TRUE AS killed_by_npc,
       bool_or(d.by_player AND d.killer_id < (SELECT min(first_character_id) FROM character_signup_month)) IS TRUE AS killed_by_veteran,
       bool_or(d.kill_date - pc.signup_date <= 7) IS TRUE AS killed_in_first_week,
       bool_or(d.ship_group = 'Capsule') IS TRUE AS lost_pod,
       mode() WITHIN GROUP (ORDER BY d.security_band) AS death_area,
       EXISTS (SELECT 1 FROM analysis.new_player_activity a3 WHERE a3.character_id = c.character_id AND a3.k = 3) AS active_month_3
FROM c
JOIN player_character pc ON pc.character_id = c.character_id
LEFT JOIN deaths d ON d.character_id = c.character_id
GROUP BY c.character_id, c.first_month, c.main_area, c.first_corp_size, c.got_kill, c.traded;

ALTER TABLE analysis.casual_player ADD PRIMARY KEY (character_id);
