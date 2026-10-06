-- Page 0: the player-run economy by month and area (CCP Monthly Economic Report): value produced, destroyed and mined, in ISK.
COPY (
  SELECT date_trunc('month', date)::date AS month, split_part(metric, ':', 2) AS area,
         sum(value) FILTER (WHERE metric LIKE 'produced_value:%') AS produced_isk,
         sum(value) FILTER (WHERE metric LIKE 'destroyed_value:%') AS destroyed_isk,
         sum(value) FILTER (WHERE metric LIKE 'mined_value:%') AS mined_isk
  FROM economy_daily
  WHERE split_part(metric, ':', 1) IN ('produced_value', 'destroyed_value', 'mined_value') AND date >= date '2024-01-01'
  GROUP BY 1, 2 ORDER BY 1, 2
) TO STDOUT WITH (FORMAT csv, HEADER);
