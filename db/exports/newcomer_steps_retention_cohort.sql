-- Tableau (act 2): newcomers of each step and cohort month still active 1, 3, 6 and 12 months after their first
-- month, as counts so retention re-aggregates under a cohort filter. Same cohorts as newcomer_steps_retention.
COPY (
  SELECT s.first_month, s.step_sort, s.step, k.k, count(*) AS newcomers, count(a.character_id) AS active
  FROM analysis.new_player_step s
  CROSS JOIN (VALUES (1), (3), (6), (12)) AS k(k)
  LEFT JOIN analysis.new_player_activity a ON a.character_id = s.character_id AND a.k = k.k
  WHERE s.first_month <= date '2025-08-01'
  GROUP BY s.first_month, s.step_sort, s.step, k.k
  ORDER BY s.first_month, s.step_sort, k.k
) TO STDOUT WITH (FORMAT csv, HEADER);
