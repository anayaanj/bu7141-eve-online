-- Page 1: EVE next to other MMOs. Peak paying subscribers (official figures), Steam players kept a year after the peak month,
-- and new-player retention. The measures differ by game: read them as a sense of scale.
COPY (
  SELECT b.game, b.metric, b.value, b.unit, b.period, s.publisher AS source
  FROM benchmark_metric b JOIN source_document s USING (source_id)
  WHERE b.metric IN ('peak_subscribers', 'steam_share_of_peak_month_after_12_months', 'steam_all_time_peak_players',
                     'retention_month_12', 'retention_month_12_launch_month_joiners', 'new_players_still_playing_after_7_days')
  ORDER BY b.metric, b.value DESC
) TO STDOUT WITH (FORMAT csv, HEADER);
