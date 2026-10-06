-- Page 1: headline numbers.
COPY (
  SELECT 'New characters created (Jan 2024 - Aug 2026)' AS kpi, sum(characters_created)::numeric AS value FROM character_signup_month
  UNION ALL SELECT 'New players who engaged (killmail or contract)', count(*) FROM analysis.new_player
  UNION ALL SELECT 'Share of new characters who engage', round((SELECT count(*) FROM analysis.new_player)::numeric / (SELECT sum(characters_created) FROM character_signup_month), 4)
  UNION ALL SELECT 'Still active after 3 months (all new players)', retention FROM analysis.retention_by_segment WHERE segment = 'All new players' AND k = 3
  UNION ALL SELECT 'Still active after 12 months (all new players)', retention FROM analysis.retention_by_segment WHERE segment = 'All new players' AND k = 12
  UNION ALL SELECT 'Still active after 3 months (joined a corp and got a kill)', retention FROM analysis.retention_by_segment WHERE segment = 'Joined a corp and got a kill' AND k = 3
  UNION ALL SELECT 'Still active after 3 months (fought in a war)', retention FROM analysis.retention_by_segment WHERE segment = 'Fought in a war (100+ pilots)' AND k = 3
  UNION ALL SELECT 'Still active after 3 months (neither)', retention FROM analysis.retention_by_segment WHERE segment = 'Neither' AND k = 3
  UNION ALL SELECT 'World of Warcraft, still active after 12 months', value FROM benchmark_metric WHERE metric = 'retention_month_12'
  UNION ALL SELECT 'CCP subscription and in-game revenue 2025 (USD)', amount FROM financial_metric WHERE metric = 'subscription_and_ingame_revenue' AND period_start = '2025-01-01'
  UNION ALL SELECT 'CCP subscription and in-game revenue 2024 (USD)', amount FROM financial_metric WHERE metric = 'subscription_and_ingame_revenue' AND period_start = '2024-01-01'
) TO STDOUT WITH (FORMAT csv, HEADER);
