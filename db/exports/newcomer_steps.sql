-- Acts 2 and 3: the four first-month steps (alone, in a corp, in an alliance, in a fleet battle) and what each goes with.
-- Cohorts with 12 months of follow-up (first month <= 2025-08-01). Revenue = months active in year one × revenue per
-- active player a month, 2025 (upper bound); compared with the $117 it cost to bring one in.
-- share_of_still_playing: how the newcomers still playing a year later split across the steps.
-- marketing_2025 / revenue_2025: 2025's marketing and first-year revenue for 2025's engaged newcomers, split by step
-- (assumes 2025's intake splits across the steps like these cohorts).
COPY (
  WITH s AS (
    SELECT s.step_sort, s.step, s.character_id, x.first_omega_month <= s.first_month + interval '12 month' AS omega
    FROM analysis.new_player_step s JOIN analysis.new_player_context x USING (character_id)
    WHERE s.first_month <= date '2025-08-01'),
  a AS (
    SELECT s.character_id, count(*) FILTER (WHERE a.k BETWEEN 0 AND 11) AS months, bool_or(a.k = 12) AS year_later
    FROM s JOIN analysis.new_player_activity a USING (character_id) GROUP BY 1),
  ue AS (SELECT arpu_month, cac_per_engaged_newcomer, engaged FROM analysis.unit_economics WHERE year = 2025)
  SELECT s.step_sort, s.step, count(*) AS newcomers,
         round(count(*)::numeric / sum(count(*)) OVER (), 4) AS share_of_newcomers,
         round(avg(coalesce(a.year_later, false)::int), 4) AS still_playing_year_later,
         round(avg(coalesce(a.months, 0)) * ue.arpu_month, 2) AS revenue_first_year,
         ue.cac_per_engaged_newcomer,
         round(avg(coalesce(s.omega, false)::int), 4) AS omega_within_12_months,
         round(avg((coalesce(a.months, 0) >= 3)::int), 4) AS active_3_months_or_more,
         count(*) FILTER (WHERE a.year_later) AS still_playing,
         round(count(*) FILTER (WHERE a.year_later)::numeric / sum(count(*) FILTER (WHERE a.year_later)) OVER (), 4) AS share_of_still_playing,
         round(count(*)::numeric / sum(count(*)) OVER () * ue.engaged * ue.cac_per_engaged_newcomer) AS marketing_2025,
         round(count(*)::numeric / sum(count(*)) OVER () * ue.engaged * avg(coalesce(a.months, 0)) * ue.arpu_month) AS revenue_2025
  FROM s LEFT JOIN a USING (character_id) CROSS JOIN ue
  GROUP BY s.step_sort, s.step, ue.arpu_month, ue.cac_per_engaged_newcomer, ue.engaged
  ORDER BY s.step_sort
) TO STDOUT WITH (FORMAT csv, HEADER);
