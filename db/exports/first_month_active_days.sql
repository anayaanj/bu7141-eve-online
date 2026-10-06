-- Act 2: how many days new players are seen in their first month, and how many are still seen 3 months later.
COPY (
  SELECT least(a.active_days, 8) AS days_seen_first_month, count(*) AS players,
         round(count(*)::numeric / sum(count(*)) OVER (), 4) AS share,
         round(count(a3.character_id)::numeric / count(*), 4) AS retention_month_3
  FROM analysis.new_player n
  JOIN character_month_activity a ON a.character_id = n.character_id AND a.month = n.first_month
  LEFT JOIN analysis.new_player_activity a3 ON a3.character_id = n.character_id AND a3.k = 3
  WHERE n.first_month <= date '2026-05-01'
  GROUP BY 1 ORDER BY 1
) TO STDOUT WITH (FORMAT csv, HEADER);
