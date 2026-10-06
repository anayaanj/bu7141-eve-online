-- Page 3: lapsed players coming back each month, with expansions attached.
COPY (
  SELECT r.month, r.returners, r.active, r.returner_share,
         (SELECT string_agg(g.title, '; ') FROM game_event g
           WHERE g.category = 'expansion' AND date_trunc('month', g.event_date) = r.month) AS expansion
  FROM analysis.returners_monthly r ORDER BY r.month
) TO STDOUT WITH (FORMAT csv, HEADER);
