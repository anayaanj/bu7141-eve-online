-- Act 0 / 2 map in one source: stargate lines (layer = link, two rows per link) and systems (layer = system), so Tableau can
-- draw both on a dual axis. Relate to sovereignty_monthly / casual_deaths_by_system on solar_system_id.
COPY (
  SELECT 'link' AS layer, row_number() OVER (ORDER BY l.from_solar_system_id, l.to_solar_system_id) AS link_id, p.point_order,
         NULL::int AS solar_system_id, NULL::text AS solar_system_name, NULL::text AS security_band, s.map_x, s.map_y
  FROM stargate_link l
  CROSS JOIN (VALUES (1), (2)) AS p(point_order)
  JOIN solar_system s ON s.solar_system_id = CASE p.point_order WHEN 1 THEN l.from_solar_system_id ELSE l.to_solar_system_id END
  JOIN solar_system o ON o.solar_system_id = CASE p.point_order WHEN 1 THEN l.to_solar_system_id ELSE l.from_solar_system_id END
  WHERE s.map_x IS NOT NULL AND o.map_x IS NOT NULL
  UNION ALL
  SELECT 'system', NULL, 1, solar_system_id, solar_system_name, security_band, map_x, map_y
  FROM solar_system WHERE map_x IS NOT NULL
  ORDER BY 1, 2, 3
) TO STDOUT WITH (FORMAT csv, HEADER);
