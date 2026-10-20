-- Act 3: how long a new player must stay to pay back the $117 it cost to bring them in (2025).
-- Per month active in the first year: revenue so far (months × revenue per active player a month) and the share of
-- new players active at least that many months. Cohorts with 12 months of follow-up (first month <= 2025-08-01).
COPY (
  WITH m AS (
    SELECT n.character_id, count(a.k) AS months
    FROM analysis.new_player n
    LEFT JOIN analysis.new_player_activity a ON a.character_id = n.character_id AND a.k BETWEEN 0 AND 11
    WHERE n.first_month <= date '2025-08-01'
    GROUP BY 1),
  ue AS (SELECT arpu_month, cac_per_engaged_newcomer FROM analysis.unit_economics WHERE year = 2025)
  SELECT k.month, round(k.month * ue.arpu_month, 2) AS revenue_so_far, ue.cac_per_engaged_newcomer,
         round(ue.cac_per_engaged_newcomer / ue.arpu_month, 2) AS break_even_months,
         round(avg((m.months >= k.month)::int), 4) AS share_active_at_least
  FROM generate_series(1, 12) AS k(month) CROSS JOIN m CROSS JOIN ue
  GROUP BY k.month, ue.arpu_month, ue.cac_per_engaged_newcomer
  ORDER BY k.month
) TO STDOUT WITH (FORMAT csv, HEADER);
