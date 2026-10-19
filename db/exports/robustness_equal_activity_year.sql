-- Act 2: the corporation effect among newcomers equally active in their first month, still playing a year later.
-- Same bands as analysis.robustness_equal_activity; cohorts with 12 months of follow-up (first month <= 2025-08-01).
COPY (
  SELECT CASE WHEN a.active_days = 1 THEN '1 day' WHEN a.active_days <= 3 THEN '2-3 days' ELSE '4+ days' END AS first_month_active_days,
         CASE WHEN n.joined_corp THEN 'In a corp' ELSE 'No corp' END AS corp,
         count(*) AS players,
         round(count(a12.character_id)::numeric / count(*), 4) AS still_playing
  FROM analysis.new_player n
  JOIN character_month_activity a ON a.character_id = n.character_id AND a.month = n.first_month
  LEFT JOIN analysis.new_player_activity a12 ON a12.character_id = n.character_id AND a12.k = 12
  WHERE n.first_month <= date '2025-08-01'
  GROUP BY 1, 2 ORDER BY 1, 2
) TO STDOUT WITH (FORMAT csv, HEADER);
