-- Act 2: what newcomers do in their first month, and how many of those who did / did not are still playing a year later.
-- Cohorts with 12 months of follow-up (first month <= 2025-08-01); a year later = seen in month 12.
-- Alliance: seen in a killmail under an alliance in the first month (newcomers who only traded cannot show one).
-- Battle: 50+ pilots in the same system and hour (any battle); 100+ is a war.
-- Died in X: first ship lost to another player in the first month was in that area (same base as first_loss_where).
COPY (
  WITH n AS (
    SELECT n.*, a12.character_id IS NOT NULL AS year_later
    FROM analysis.new_player n
    LEFT JOIN analysis.new_player_activity a12 ON a12.character_id = n.character_id AND a12.k = 12
    WHERE n.first_month <= date '2025-08-01'),
  al AS (
    SELECT DISTINCT p.character_id
    FROM n
    JOIN killmail_participant p ON p.character_id = n.character_id AND p.alliance_id IS NOT NULL
    JOIN killmail k ON k.killmail_id = p.killmail_id
     AND k.kill_date >= n.first_month AND k.kill_date < n.first_month + interval '1 month'),
  loss AS (
    SELECT DISTINCT ON (n.character_id) n.character_id, s.security_band
    FROM n
    JOIN killmail_participant pv ON pv.character_id = n.character_id AND pv.role = 'victim'
    JOIN killmail k ON k.killmail_id = pv.killmail_id
     AND k.kill_date >= n.first_month AND k.kill_date < n.first_month + interval '1 month'
    JOIN solar_system s ON s.solar_system_id = k.solar_system_id
    WHERE EXISTS (SELECT 1 FROM killmail_participant a WHERE a.killmail_id = k.killmail_id AND a.role = 'attacker' AND a.character_id IS NOT NULL)
    ORDER BY n.character_id, k.killmail_time),
  b AS (
    SELECT n.joined_corp, al.character_id IS NOT NULL AS in_alliance, n.got_kill, n.traded, n.lost_ship,
           n.first_month_battle = 'war' AS big_battle,
           n.first_month_battle <> 'none' AS any_battle,
           coalesce(l.security_band LIKE 'Null Sec%', false) AS died_null,
           coalesce(l.security_band = 'Low Sec', false) AS died_low,
           coalesce(l.security_band = 'High Sec', false) AS died_high,
           n.year_later
    FROM n LEFT JOIN al USING (character_id) LEFT JOIN loss l USING (character_id)),
  l AS (
    SELECT 1 AS sort, 'Joined a player corporation' AS behaviour, joined_corp AS did, year_later FROM b
    UNION ALL SELECT 2, 'Flew in an alliance', in_alliance, year_later FROM b
    UNION ALL SELECT 3, 'Got a kill', got_kill, year_later FROM b
    UNION ALL SELECT 4, 'Fought in a 100+ pilot battle', big_battle, year_later FROM b
    UNION ALL SELECT 5, 'Fought in any battle (50+ pilots)', any_battle, year_later FROM b
    UNION ALL SELECT 6, 'Traded (issued a contract)', traded, year_later FROM b
    UNION ALL SELECT 7, 'Lost a ship', lost_ship, year_later FROM b
    UNION ALL SELECT 8, 'Died in null-sec', died_null, year_later FROM b
    UNION ALL SELECT 9, 'Died in low-sec', died_low, year_later FROM b
    UNION ALL SELECT 10, 'Died in high-sec', died_high, year_later FROM b)
  SELECT sort, behaviour, count(*) AS newcomers, round(avg(did::int), 4) AS share_did,
         round(avg(year_later::int) FILTER (WHERE did), 4) AS still_playing_did,
         round(avg(year_later::int) FILTER (WHERE NOT did), 4) AS still_playing_did_not
  FROM l GROUP BY 1, 2 ORDER BY 1
) TO STDOUT WITH (FORMAT csv, HEADER);
