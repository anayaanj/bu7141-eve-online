-- Pages 1 and 3: the monthly funnel. Signups (exact, every character created) -> engaged (seen in killmails
-- or contracts in their first month) -> still active 3 months later. Major events attached to their month.
COPY (
  SELECT s.month, s.characters_created AS signups,
         count(n.character_id) AS engaged_new_players,
         round(count(n.character_id)::numeric / s.characters_created, 4) AS engaged_share,
         count(a.character_id) AS active_month_3,
         CASE WHEN s.month + interval '3 month' <= date '2026-08-01'
              THEN round(count(a.character_id)::numeric / nullif(count(n.character_id), 0), 4) END AS retention_month_3,
         (SELECT string_agg(g.title, '; ' ORDER BY g.event_date) FROM game_event g
           WHERE g.category IN ('expansion', 'company', 'monetization') AND date_trunc('month', g.event_date) = s.month) AS events
  FROM character_signup_month s
  LEFT JOIN analysis.new_player n ON n.first_month = s.month
  LEFT JOIN analysis.new_player_activity a ON a.character_id = n.character_id AND a.k = 3
  GROUP BY s.month, s.characters_created ORDER BY s.month
) TO STDOUT WITH (FORMAT csv, HEADER);
