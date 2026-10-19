-- Act 2 Sankey: newcomers we can see, by days seen in their first month (1 day / 2+ days), then still seen at month 12 or not.
-- Cohorts with 12 months of follow-up only (first month <= 2025-08-01), the same base as the act 1 "still playing a year later".
COPY (
  WITH p AS (
    SELECT CASE WHEN a.active_days = 1 THEN '1 day' ELSE '2+ days' END AS days_seen,
           CASE WHEN a12.character_id IS NOT NULL THEN 'Still playing a year later' ELSE 'Gone' END AS a_year_later
    FROM analysis.new_player n
    JOIN character_month_activity a ON a.character_id = n.character_id AND a.month = n.first_month
    LEFT JOIN analysis.new_player_activity a12 ON a12.character_id = n.character_id AND a12.k = 12
    WHERE n.first_month <= date '2025-08-01'
  )
  SELECT days_seen, a_year_later, count(*) AS players,
         round(count(*)::numeric / sum(count(*)) OVER (), 4) AS share,
         round(count(*)::numeric / sum(count(*)) OVER (PARTITION BY days_seen), 4) AS share_of_days_seen
  FROM p GROUP BY 1, 2 ORDER BY 1, 2
) TO STDOUT WITH (FORMAT csv, HEADER);
