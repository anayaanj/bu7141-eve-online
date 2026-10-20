-- Tableau (acts 2-4): the four first-month steps per cohort month, as additive counts so every share and rate can be
-- re-aggregated under a cohort filter. Same cohorts and measures as newcomer_steps (first month <= 2025-08-01).
-- revenue_first_year = active months in year one × revenue per active player a month (2025, upper bound).
COPY (
  WITH s AS (
    SELECT s.step_sort, s.step, s.first_month, s.character_id,
           coalesce(x.first_omega_month <= s.first_month + interval '12 month', false) AS omega
    FROM analysis.new_player_step s JOIN analysis.new_player_context x USING (character_id)
    WHERE s.first_month <= date '2025-08-01'),
  a AS (
    SELECT s.character_id, count(*) FILTER (WHERE a.k BETWEEN 0 AND 11) AS months, bool_or(a.k = 12) AS year_later
    FROM s JOIN analysis.new_player_activity a USING (character_id) GROUP BY 1),
  ue AS (SELECT arpu_month, cac_per_engaged_newcomer, engaged FROM analysis.unit_economics WHERE year = 2025)
  SELECT s.first_month, s.step_sort, s.step, count(*) AS newcomers,
         count(*) FILTER (WHERE a.year_later) AS still_playing,
         count(*) FILTER (WHERE s.omega) AS omega_within_12_months,
         count(*) FILTER (WHERE coalesce(a.months, 0) >= 3) AS active_3_months_or_more,
         sum(coalesce(a.months, 0)) AS active_months_first_year,
         round(sum(coalesce(a.months, 0)) * ue.arpu_month, 2) AS revenue_first_year,
         ue.arpu_month, ue.cac_per_engaged_newcomer, ue.engaged AS engaged_2025
  FROM s LEFT JOIN a USING (character_id) CROSS JOIN ue
  GROUP BY s.first_month, s.step_sort, s.step, ue.arpu_month, ue.cac_per_engaged_newcomer, ue.engaged
  ORDER BY s.first_month, s.step_sort
) TO STDOUT WITH (FORMAT csv, HEADER);
