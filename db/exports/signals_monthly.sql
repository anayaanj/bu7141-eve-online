-- Context lines for every page: players online, interest (Twitch, Steam, Google Trends) and sentiment (Steam reviews, forums).
COPY (
  WITH months AS (SELECT generate_series(date '2024-01-01', date '2026-08-01', interval '1 month')::date AS month),
  online AS (SELECT date_trunc('month', date)::date AS month, round(avg(avg_players)) AS players_online_avg,
                    max(peak_players) AS players_online_peak, sum(outage_minutes) AS outage_minutes
             FROM players_online_daily GROUP BY 1),
  interest AS (SELECT date_trunc('month', period_start)::date AS month,
                      max(value) FILTER (WHERE source = 'twitch' AND metric = 'hours_watched') AS twitch_hours_watched,
                      max(value) FILTER (WHERE source = 'twitch' AND metric = 'peak_viewers') AS twitch_peak_viewers,
                      max(value) FILTER (WHERE source = 'steam' AND metric = 'avg_players') AS steam_avg_players,
                      round(avg(value) FILTER (WHERE source = 'google_trends' AND granularity = 'week'), 1) AS search_interest
               FROM interest_metric GROUP BY 1),
  steam AS (SELECT date_trunc('month', created_date)::date AS month, count(*) AS steam_reviews,
                   round(avg(voted_up::int), 4) AS steam_positive_share FROM steam_review GROUP BY 1),
  forum AS (SELECT date_trunc('month', p.created_date)::date AS month,
                   count(*) FILTER (WHERE t.matched_query IN ('omega price', 'plex price', 'subscription')) AS forum_posts_pricing,
                   count(*) FILTER (WHERE t.matched_query = 'new player') AS forum_posts_new_players,
                   count(*) FILTER (WHERE t.matched_query IN ('pearl abyss', 'fenris')) AS forum_posts_ownership
            FROM forum_post p JOIN forum_topic t USING (topic_id) GROUP BY 1)
  SELECT m.month, o.players_online_avg, o.players_online_peak, o.outage_minutes, i.twitch_hours_watched,
         i.twitch_peak_viewers, i.steam_avg_players, i.search_interest, s.steam_reviews, s.steam_positive_share,
         f.forum_posts_pricing, f.forum_posts_new_players, f.forum_posts_ownership
  FROM months m LEFT JOIN online o USING (month) LEFT JOIN interest i USING (month)
  LEFT JOIN steam s USING (month) LEFT JOIN forum f USING (month) ORDER BY m.month
) TO STDOUT WITH (FORMAT csv, HEADER);
