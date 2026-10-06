-- Page 5: three months before the sale of CCP (Feb-Apr 2026) vs three months after (Jun-Aug 2026; Cradle of War launched in June).
COPY (
  WITH p AS (SELECT * FROM (VALUES ('Before (Feb-Apr 2026)', date '2026-02-01', date '2026-04-30'),
                                   ('After (Jun-Aug 2026)',  date '2026-06-01', date '2026-08-31')) v(period, s, e))
  SELECT p.period,
    (SELECT round(avg(characters_created)) FROM character_signup_month WHERE month BETWEEN p.s AND p.e) AS signups_per_month,
    (SELECT round(avg(c)) FROM (SELECT count(*) c FROM character_month_activity WHERE month BETWEEN p.s AND p.e GROUP BY month) x) AS active_characters_per_month,
    (SELECT round(avg(returners)) FROM analysis.returners_monthly WHERE month BETWEEN p.s AND p.e) AS returners_per_month,
    (SELECT round(avg(avg_players)) FROM players_online_daily WHERE date BETWEEN p.s AND p.e) AS players_online_avg,
    (SELECT round(sum(average_price * volume) / sum(volume)) FROM market_history_daily WHERE type_id = 44992 AND date BETWEEN p.s AND p.e) AS plex_avg_price_isk,
    (SELECT round(avg(voted_up::int), 4) FROM steam_review WHERE created_date BETWEEN p.s AND p.e) AS steam_positive_share
  FROM p ORDER BY p.s
) TO STDOUT WITH (FORMAT csv, HEADER);
