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
       || CASE WHEN joined_corp THEN ', in a corp' ELSE ', no corp' END FROM analysis.new_player;

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
