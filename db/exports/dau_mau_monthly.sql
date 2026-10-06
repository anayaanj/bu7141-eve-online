-- Page 0 / 1: engagement. Average daily active characters (DAU), monthly active characters (MAU), stickiness (DAU / MAU),
-- and players online at the same time (all players, not just visible ones).
COPY (
  WITH d AS (SELECT date_trunc('month', date)::date AS month, round(avg(characters)) AS dau FROM analysis.daily_active GROUP BY 1),
  m AS (SELECT month, count(*) AS mau FROM character_month_activity GROUP BY 1),
  o AS (SELECT date_trunc('month', date)::date AS month, round(avg(avg_players)) AS players_online FROM players_online_daily GROUP BY 1)
  SELECT d.month, d.dau, m.mau, round(d.dau / m.mau, 4) AS dau_mau, o.players_online
  FROM d JOIN m USING (month) LEFT JOIN o USING (month) ORDER BY 1
) TO STDOUT WITH (FORMAT csv, HEADER);
