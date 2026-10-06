-- Page 0: where the fighting is, by month and solar system: ships destroyed and the largest battle (pilots in its busiest hour).
-- Join to map_systems.csv on solar_system_id for the name, area and map position.
COPY (
  WITH kills AS (
    SELECT date_trunc('month', kill_date)::date AS month, solar_system_id, count(*) AS ships_destroyed
    FROM killmail GROUP BY 1, 2),
  battles AS (
    SELECT date_trunc('month', b.battle_date)::date AS month, b.solar_system_id, count(*) AS battles,
           max(bp.peak_hour_pilots) AS largest_battle_pilots
    FROM battle b JOIN analysis.battle_peak bp USING (battle_id) GROUP BY 1, 2)
  SELECT k.month, k.solar_system_id, k.ships_destroyed, coalesce(b.battles, 0) AS battles, b.largest_battle_pilots
  FROM kills k JOIN solar_system s USING (solar_system_id)
  LEFT JOIN battles b USING (month, solar_system_id)
  WHERE s.map_x IS NOT NULL
  ORDER BY 1, 2
) TO STDOUT WITH (FORMAT csv, HEADER);
