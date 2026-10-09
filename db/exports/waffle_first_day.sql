-- Act 2 waffle: 100 newcomers we can see, one cell each (10 x 10), coloured by what their first month looked like.
COPY (
  WITH s AS (
    SELECT round(100 * avg((d = 1)::int)) AS once FROM (
      SELECT a.active_days AS d FROM analysis.new_player n
      JOIN character_month_activity a ON a.character_id = n.character_id AND a.month = n.first_month
      WHERE n.first_month <= date '2026-05-01') x),
  c AS (
    SELECT avg((killed_by_player AND NOT got_kill)::int) AS by_player, avg((killed_by_npc AND NOT killed_by_player AND NOT got_kill)::int) AS by_npc
    FROM analysis.casual_player WHERE first_month <= date '2026-05-01'),
  n AS (SELECT s.once, round(s.once * c.by_player) AS by_player, round(s.once * c.by_npc) AS by_npc FROM s, c)
  SELECT g AS cell, (g - 1) % 10 + 1 AS x, (g - 1) / 10 + 1 AS y,
         CASE WHEN g <= n.by_player THEN 'Seen once: killed by another player'
              WHEN g <= n.by_player + n.by_npc THEN 'Seen once: killed by the computer'
              WHEN g <= n.once THEN 'Seen once: other (a kill or a trade)'
              ELSE 'Seen on 2+ days' END AS category
  FROM generate_series(1, 100) g, n ORDER BY g
) TO STDOUT WITH (FORMAT csv, HEADER);
