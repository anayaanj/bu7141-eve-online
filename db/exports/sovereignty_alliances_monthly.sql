-- Act 0: systems held on the first day of every month by the three alliances in the story, and all others together.
COPY (
  SELECT s.date AS month,
         CASE WHEN a.alliance_name IN ('Goonswarm Federation', 'Pandemic Horde', 'Fraternity.') THEN rtrim(a.alliance_name, '.') ELSE 'Other alliances' END AS alliance,
         count(*) AS systems_held
  FROM sovereignty_daily s LEFT JOIN alliance a USING (alliance_id)
  WHERE extract(day FROM s.date) = 1
  GROUP BY 1, 2 ORDER BY 1, 3 DESC
) TO STDOUT WITH (FORMAT csv, HEADER);
