-- Act 2: 100 signups as dots (10 x 10), on our own base: never seen fighting or trading, seen then gone within the year, still playing a year later.
COPY (
  WITH n AS (
    SELECT round(100 * (SELECT count(*) FROM analysis.new_player)::numeric / (SELECT sum(characters_created) FROM character_signup_month)) AS seen,
           round(100 * (SELECT count(*) FROM analysis.new_player)::numeric / (SELECT sum(characters_created) FROM character_signup_month)
                     * (SELECT retention FROM analysis.retention_by_segment WHERE segment = 'All new players' AND k = 12)) AS kept)
  SELECT g AS cell, (g - 1) % 10 + 1 AS x, (g - 1) / 10 + 1 AS y,
         CASE WHEN g <= 100 - n.seen THEN 'Never seen fighting or trading with another player'
              WHEN g <= 100 - n.kept THEN 'Seen, then gone within the year'
              ELSE 'Still playing a year later' END AS kind
  FROM generate_series(1, 100) g, n ORDER BY g
) TO STDOUT WITH (FORMAT csv, HEADER);
