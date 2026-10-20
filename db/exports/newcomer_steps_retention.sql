-- Act 2: share of each first-month step still active 1, 3, 6 and 12 months after the first month.
-- Same cohorts at every point (first month <= 2025-08-01), so month 12 matches newcomer_steps.
COPY (
  SELECT s.step_sort, s.step, k.k, count(*) AS newcomers, count(a.character_id) AS active,
         round(count(a.character_id)::numeric / count(*), 4) AS retention
  FROM analysis.new_player_step s
  CROSS JOIN (VALUES (1), (3), (6), (12)) AS k(k)
  LEFT JOIN analysis.new_player_activity a ON a.character_id = s.character_id AND a.k = k.k
  WHERE s.first_month <= date '2025-08-01'
  GROUP BY s.step_sort, s.step, k.k
  ORDER BY s.step_sort, k.k
) TO STDOUT WITH (FORMAT csv, HEADER);
