-- Act 2 map: newcomers' first ship lost to another player in their first month, by solar system (same base as first_loss_where).
-- Join to map_layers.csv on solar_system_id for the position.
COPY (
  WITH n AS (
    SELECT n.character_id, n.first_month, a12.character_id IS NOT NULL AS year_later
    FROM analysis.new_player n
    LEFT JOIN analysis.new_player_activity a12 ON a12.character_id = n.character_id AND a12.k = 12
    WHERE n.first_month <= date '2025-08-01'),
  loss AS (
    SELECT DISTINCT ON (n.character_id) n.character_id, n.year_later, k.solar_system_id
    FROM n
    JOIN killmail_participant pv ON pv.character_id = n.character_id AND pv.role = 'victim'
    JOIN killmail k ON k.killmail_id = pv.killmail_id
     AND k.kill_date >= n.first_month AND k.kill_date < n.first_month + interval '1 month'
    WHERE EXISTS (SELECT 1 FROM killmail_participant a WHERE a.killmail_id = k.killmail_id AND a.role = 'attacker' AND a.character_id IS NOT NULL)
    ORDER BY n.character_id, k.killmail_time)
  SELECT l.solar_system_id, s.solar_system_name, s.security_band, count(*) AS newcomers,
         round(avg(l.year_later::int), 4) AS still_playing
  FROM loss l JOIN solar_system s USING (solar_system_id)
  GROUP BY 1, 2, 3 ORDER BY 4 DESC
) TO STDOUT WITH (FORMAT csv, HEADER);
