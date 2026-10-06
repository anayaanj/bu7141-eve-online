-- Act 0: who holds space. The alliance holding each system on the first day of every month.
-- The three alliances in the story get their own colour (highlight); every other alliance is "Other alliances". Join to map_layers.
COPY (
  SELECT s.date AS month, s.solar_system_id, s.alliance_id,
         coalesce(a.alliance_name, 'Alliance ' || s.alliance_id) AS alliance_name,
         CASE WHEN a.alliance_name IN ('Goonswarm Federation', 'Pandemic Horde', 'Fraternity.') THEN rtrim(a.alliance_name, '.') ELSE 'Other alliances' END AS highlight
  FROM sovereignty_daily s LEFT JOIN alliance a USING (alliance_id)
  WHERE extract(day FROM s.date) = 1
  ORDER BY 1, 2
) TO STDOUT WITH (FORMAT csv, HEADER);
