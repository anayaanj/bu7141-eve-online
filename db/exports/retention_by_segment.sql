-- Page 2 (main chart): share of new players still active k months after their first month, by first-month behaviour.
-- Includes the World of Warcraft benchmark measured the same way (scripts/wowah_retention.py).
COPY (
  SELECT segment, k, players, active, retention, 'EVE Online' AS game FROM analysis.retention_by_segment
  UNION ALL
  SELECT 'World of Warcraft (2006-07)', replace(metric, 'retention_month_', '')::int, NULL, NULL, value, game
  FROM benchmark_metric WHERE metric LIKE 'retention_month_%'
  ORDER BY game, segment, k
) TO STDOUT WITH (FORMAT csv, HEADER);
