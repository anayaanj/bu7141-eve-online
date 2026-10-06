-- Act 2 map: where casual newcomers (seen on one day) were killed by other players in their first month, by solar system.
-- Join to map_systems.csv on solar_system_id for the position; is_starter_system marks the starting systems.
COPY (
  SELECT k.solar_system_id, s.security_band, s.is_starter_system,
         count(DISTINCT c.character_id) AS casual_newcomers_killed
  FROM analysis.casual_player c
  JOIN killmail_participant v ON v.character_id = c.character_id AND v.role = 'victim'
  JOIN killmail k ON k.killmail_id = v.killmail_id
   AND k.kill_date >= c.first_month AND k.kill_date < c.first_month + interval '1 month'
  JOIN solar_system s ON s.solar_system_id = k.solar_system_id
  WHERE c.first_month <= date '2026-05-01' AND s.map_x IS NOT NULL
    AND EXISTS (SELECT 1 FROM killmail_participant a WHERE a.killmail_id = k.killmail_id AND a.role = 'attacker' AND a.character_id IS NOT NULL)
  GROUP BY 1, 2, 3 ORDER BY 4 DESC
) TO STDOUT WITH (FORMAT csv, HEADER);
