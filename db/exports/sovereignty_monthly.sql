-- Page 0: who holds space. The alliance holding each system on the first day of every month.
-- The 12 alliances holding the most system-days get their own colour; the rest are "Other". Join to map_systems.csv.
COPY (
  WITH top AS (
    SELECT alliance_id FROM sovereignty_daily GROUP BY alliance_id ORDER BY count(*) DESC LIMIT 12)
  SELECT s.date AS month, s.solar_system_id, s.alliance_id,
         coalesce(a.alliance_name, 'Alliance ' || s.alliance_id) AS alliance_name,
         CASE WHEN s.alliance_id IN (SELECT alliance_id FROM top) THEN coalesce(a.alliance_name, 'Alliance ' || s.alliance_id)
              ELSE 'Other' END AS colour_group
  FROM sovereignty_daily s LEFT JOIN alliance a USING (alliance_id)
  WHERE extract(day FROM s.date) = 1
  ORDER BY 1, 2
) TO STDOUT WITH (FORMAT csv, HEADER);
