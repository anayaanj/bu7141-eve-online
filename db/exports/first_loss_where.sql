-- Act 2: where newcomers lose their first ship to another player in their first month, and how many are still playing a year later.
-- One row per area, plus the newcomers not killed by a player. Cohorts with 12 months of follow-up (first month <= 2025-08-01).
COPY (
  WITH n AS (
    SELECT n.character_id, n.first_month, a12.character_id IS NOT NULL AS year_later
    FROM analysis.new_player n
    LEFT JOIN analysis.new_player_activity a12 ON a12.character_id = n.character_id AND a12.k = 12
    WHERE n.first_month <= date '2025-08-01'),
  loss AS (
    SELECT DISTINCT ON (n.character_id) n.character_id, k.solar_system_id, pv.ship_type_id
    FROM n
    JOIN killmail_participant pv ON pv.character_id = n.character_id AND pv.role = 'victim'
    JOIN killmail k ON k.killmail_id = pv.killmail_id
     AND k.kill_date >= n.first_month AND k.kill_date < n.first_month + interval '1 month'
    WHERE EXISTS (SELECT 1 FROM killmail_participant a WHERE a.killmail_id = k.killmail_id AND a.role = 'attacker' AND a.character_id IS NOT NULL)
    ORDER BY n.character_id, k.killmail_time),
  d AS (
    SELECT n.year_later,
           CASE WHEN l.character_id IS NULL THEN 'Not killed by a player'
                WHEN s.security_band = 'High Sec' THEN 'High-sec'
                WHEN s.security_band = 'Low Sec' THEN 'Low-sec'
                WHEN s.security_band LIKE 'Null Sec%' THEN 'Null-sec'
                WHEN s.security_band LIKE 'Wormhole%' THEN 'Wormhole'
                ELSE 'Other' END AS area,
           g.group_name IN ('Corvette', 'Frigate', 'Destroyer', 'Shuttle') AS starter_hull
    FROM n
    LEFT JOIN loss l USING (character_id)
    LEFT JOIN solar_system s ON s.solar_system_id = l.solar_system_id
    LEFT JOIN item_type it ON it.type_id = l.ship_type_id
    LEFT JOIN item_group g ON g.group_id = it.group_id)
  SELECT area, count(*) AS newcomers,
         round(count(*)::numeric / sum(count(*)) FILTER (WHERE area <> 'Not killed by a player') OVER (), 4) AS share_of_first_losses,
         round(avg(year_later::int), 4) AS still_playing,
         round(avg(starter_hull::int), 4) AS share_starter_hull
  FROM d GROUP BY 1 ORDER BY 2 DESC
) TO STDOUT WITH (FORMAT csv, HEADER);
