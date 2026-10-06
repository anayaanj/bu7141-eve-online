-- Page 0 (what is EVE): every solar system on CCP's 2D map, for the map background.
COPY (
  SELECT s.solar_system_id, s.solar_system_name, r.region_name, s.security_band, s.map_x, s.map_y
  FROM solar_system s JOIN constellation c USING (constellation_id) JOIN region r USING (region_id)
  WHERE s.map_x IS NOT NULL ORDER BY 1
) TO STDOUT WITH (FORMAT csv, HEADER);
