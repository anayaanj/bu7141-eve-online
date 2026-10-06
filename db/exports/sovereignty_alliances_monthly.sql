-- Page 0: systems held by each alliance on the first day of every month (the 12 biggest holders, the rest as "Other").
COPY (
  WITH top AS (
    SELECT alliance_id FROM sovereignty_daily GROUP BY alliance_id ORDER BY count(*) DESC LIMIT 12)
  SELECT s.date AS month,
         CASE WHEN s.alliance_id IN (SELECT alliance_id FROM top) THEN coalesce(a.alliance_name, 'Alliance ' || s.alliance_id)
              ELSE 'Other' END AS alliance,
         count(*) AS systems_held
  FROM sovereignty_daily s LEFT JOIN alliance a USING (alliance_id)
  WHERE extract(day FROM s.date) = 1
  GROUP BY 1, 2 ORDER BY 1, 3 DESC
) TO STDOUT WITH (FORMAT csv, HEADER);
