-- Page 0: stargate connections as line paths (two rows per link: point_order 1 and 2), for the map lines in Tableau.
COPY (
  SELECT row_number() OVER (ORDER BY l.from_solar_system_id, l.to_solar_system_id) AS link_id, p.point_order, s.map_x, s.map_y
  FROM stargate_link l
  CROSS JOIN (VALUES (1), (2)) AS p(point_order)
  JOIN solar_system s ON s.solar_system_id = CASE p.point_order WHEN 1 THEN l.from_solar_system_id ELSE l.to_solar_system_id END
  JOIN solar_system o ON o.solar_system_id = CASE p.point_order WHEN 1 THEN l.to_solar_system_id ELSE l.from_solar_system_id END
  WHERE s.map_x IS NOT NULL AND o.map_x IS NOT NULL
  ORDER BY link_id, p.point_order
) TO STDOUT WITH (FORMAT csv, HEADER);
