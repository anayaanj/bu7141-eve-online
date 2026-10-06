-- Page 4: PLEX (bought with real money, traded for ISK): volume-weighted average price and volume across all regions.
COPY (
  SELECT date_trunc('month', date)::date AS month,
         round(sum(average_price * volume) / sum(volume)) AS plex_avg_price_isk, sum(volume) AS plex_volume
  FROM market_history_daily WHERE type_id = 44992 GROUP BY 1 ORDER BY 1
) TO STDOUT WITH (FORMAT csv, HEADER);
