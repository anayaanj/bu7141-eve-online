-- Page 0: money supply. ISK in players' and corporations' wallets at month end, and ISK created (faucets) vs removed (sinks).
COPY (
  WITH m AS (SELECT date_trunc('month', date)::date AS month, metric, date, value FROM economy_daily)
  SELECT month,
         max(value) FILTER (WHERE metric = 'total_isk' AND date = (SELECT max(date) FROM m m2 WHERE m2.month = m.month AND m2.metric = 'total_isk')) AS isk_supply_month_end,
         sum(value) FILTER (WHERE metric LIKE 'faucet:%') AS isk_created,
         sum(value) FILTER (WHERE metric LIKE 'sink:%') AS isk_removed
  FROM m WHERE month >= date '2024-01-01'
  GROUP BY month ORDER BY month
) TO STDOUT WITH (FORMAT csv, HEADER);
