-- Act 1: who plays today. Characters active in August 2026 by the age of the character (from its signup date),
-- with the share seen flying an Omega-only ship that month. Veteran = a year or more in the game.
COPY (
  SELECT CASE WHEN pc.signup_date >= date '2025-09-01' THEN 'Under a year'
              WHEN pc.signup_date >= date '2023-09-01' THEN '1 - 3 years'
              WHEN pc.signup_date >= date '2016-09-01' THEN '3 - 10 years' ELSE '10+ years' END AS age,
         CASE WHEN pc.signup_date >= date '2025-09-01' THEN 4 WHEN pc.signup_date >= date '2023-09-01' THEN 3
              WHEN pc.signup_date >= date '2016-09-01' THEN 2 ELSE 1 END AS sort,
         CASE WHEN pc.signup_date >= date '2025-09-01' THEN 'Newcomer' ELSE 'Veteran' END AS kind,
         count(*) AS characters,
         round(count(*)::numeric / sum(count(*)) OVER (), 4) AS share,
         round(avg(a.flew_omega_ship::int), 4) AS omega_share
  FROM character_month_activity a JOIN player_character pc USING (character_id)
  WHERE a.month = date '2026-08-01' AND pc.signup_date IS NOT NULL
  GROUP BY 1, 2, 3 ORDER BY 2
) TO STDOUT WITH (FORMAT csv, HEADER);
