-- Page 0: headline numbers that describe the game to someone who has never played it (Jan 2024 - Aug 2026).
COPY (
  SELECT 'Players online at the same time (average)' AS fact, round(avg(avg_players))::numeric AS value, '' AS detail FROM players_online_daily WHERE date >= '2024-01-01'
  UNION ALL SELECT 'Ships destroyed per day (average)', round(count(*)::numeric / (date '2026-08-31' - date '2024-01-01' + 1)), '' FROM killmail
  UNION ALL SELECT 'Battles with 100+ pilots', count(*), '' FROM battle WHERE battle_class = 'war'
  UNION ALL (SELECT 'Largest battle (pilots in one hour)', bp.peak_hour_pilots, s.solar_system_name || ', ' || b.battle_date FROM battle b JOIN analysis.battle_peak bp USING (battle_id) JOIN solar_system s USING (solar_system_id) ORDER BY bp.peak_hour_pilots DESC LIMIT 1)
  UNION ALL SELECT 'Player corporations seen fighting', count(DISTINCT p.corporation_id), '' FROM killmail_participant p JOIN corporation c USING (corporation_id) WHERE NOT c.is_npc
  UNION ALL SELECT 'Alliances seen fighting', count(DISTINCT alliance_id), '' FROM killmail_participant WHERE alliance_id IS NOT NULL
  UNION ALL SELECT 'Value destroyed per month (ISK, average)', round(sum(value) / count(DISTINCT date_trunc('month', date))), '' FROM economy_daily WHERE metric LIKE 'destroyed_value:%' AND date >= '2024-01-01'
  UNION ALL SELECT 'Value produced per month (ISK, average)', round(sum(value) / count(DISTINCT date_trunc('month', date))), '' FROM economy_daily WHERE metric LIKE 'produced_value:%' AND date >= '2024-01-01'
  UNION ALL SELECT 'Solar systems on the map', count(*), '' FROM solar_system WHERE map_x IS NOT NULL
  UNION ALL SELECT 'Years online', extract(year FROM age(date '2026-08-31', date '2003-05-06')), 'since 6 May 2003'
  UNION ALL SELECT 'Subscribers at the peak', value, period FROM benchmark_metric WHERE game = 'EVE Online' AND metric = 'peak_subscribers'
  UNION ALL SELECT 'Subscription and in-game revenue 2025 (USD)', amount, 'CCP audited accounts' FROM financial_metric WHERE metric = 'subscription_and_ingame_revenue' AND period_start = '2025-01-01'
) TO STDOUT WITH (FORMAT csv, HEADER);
