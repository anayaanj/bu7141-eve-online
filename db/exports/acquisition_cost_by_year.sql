-- Act 4: what buying a newcomer costs, by year, in long format so every row sits on one labelled scale (no two-axis charts).
COPY (
  WITH u AS (SELECT * FROM analysis.unit_economics),
  m AS (
    SELECT year, 'Marketing spend (USD)' AS measure, marketing AS value, 1 AS ord FROM u
    UNION ALL SELECT year, 'Signups (characters created)', signups, 2 FROM u
    UNION ALL SELECT year, 'Newcomers who engaged', engaged, 3 FROM u
    UNION ALL SELECT year, 'Cost per signup (USD)', cac_per_signup, 4 FROM u
    UNION ALL SELECT year, 'Cost per engaged newcomer (USD)', cac_per_engaged_newcomer, 5 FROM u)
  SELECT year, measure, value,
         round(value / lag(value) OVER (PARTITION BY measure ORDER BY year) - 1, 4) AS change_vs_prior
  FROM m ORDER BY ord, year
) TO STDOUT WITH (FORMAT csv, HEADER);
