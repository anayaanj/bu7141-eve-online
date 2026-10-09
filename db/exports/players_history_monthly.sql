-- Page 0: "23 years of EVE". Average and peak players online by month (EVE-Offline, from June 2006) and the
-- subscriber milestones CCP announced before that series starts (benchmark_metric, game = EVE Online).
-- Two series on one player-count scale: series = 'players_online' (monthly) or 'subscribers' (one row per announcement).
COPY (
  SELECT date_trunc('month', date)::date AS month, 'players_online' AS series,
         round(avg(avg_players)) AS value, max(peak_players) AS peak, NULL AS source
  FROM players_online_daily GROUP BY 1
  UNION ALL
  SELECT (b.period || '-01')::date, 'subscribers', b.value, NULL, d.publisher
  FROM benchmark_metric b JOIN source_document d USING (source_id)
  WHERE b.game = 'EVE Online' AND b.metric IN ('subscribers', 'peak_subscribers')
  ORDER BY 1, 2
) TO STDOUT WITH (FORMAT csv, HEADER);
