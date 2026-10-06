-- Page 1: retention heatmap, first month (cohort) x months since (k), all new players.
COPY (
  SELECT n.first_month AS cohort, k.k, count(*) AS players, count(a.character_id) AS active,
         round(count(a.character_id)::numeric / count(*), 4) AS retention
  FROM analysis.new_player n
  CROSS JOIN generate_series(0, 12) AS k(k)
  LEFT JOIN analysis.new_player_activity a ON a.character_id = n.character_id AND a.k = k.k
  WHERE n.first_month + make_interval(months => k.k) <= date '2026-08-01'
  GROUP BY 1, 2 ORDER BY 1, 2
) TO STDOUT WITH (FORMAT csv, HEADER);
