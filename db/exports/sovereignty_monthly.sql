-- Act 0: who holds space. The alliance holding each system on the first day of every month.
-- rank orders alliances by the system-months they held over the period (1 = Goonswarm), so each alliance keeps one colour
-- across months; highlight is the display name. Join to map_layers.
COPY (
  WITH monthly AS (
    SELECT s.date AS month, s.solar_system_id, s.alliance_id, coalesce(a.alliance_name, 'Alliance ' || s.alliance_id) AS alliance_name
    FROM sovereignty_daily s LEFT JOIN alliance a USING (alliance_id) WHERE extract(day FROM s.date) = 1),
  ranked AS (SELECT alliance_id, rank() OVER (ORDER BY count(*) DESC, alliance_id) AS rank FROM monthly GROUP BY alliance_id)
  SELECT m.month, m.solar_system_id, m.alliance_id, m.alliance_name, rtrim(m.alliance_name, '.') AS highlight, r.rank
  FROM monthly m JOIN ranked r USING (alliance_id)
  ORDER BY 1, 2
) TO STDOUT WITH (FORMAT csv, HEADER);
