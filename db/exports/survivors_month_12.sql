-- Act 3 closer: the newcomers still active 12 months after their first month: how many were in a player corporation, under an alliance,
-- flying an Omega-only ship or getting a kill that month, against the same shares in everyone's first month.
COPY (
  WITH s AS (SELECT character_id, first_month, (first_month + interval '12 month')::date AS m12 FROM analysis.new_player WHERE first_month + interval '12 month' <= date '2026-08-01'),
  pick AS (
    SELECT 'Still active at month 12' AS base, 1 AS sort, s.character_id, s.m12 AS m FROM s
    UNION ALL SELECT 'Everyone, in their first month', 2, character_id, first_month FROM analysis.new_player),
  a AS (
    SELECT p.base, p.sort, cma.in_player_corporation, cma.flew_omega_ship, cma.kills > 0 AS got_kill,
           EXISTS (SELECT 1 FROM killmail_participant kp JOIN killmail k USING (killmail_id)
                   WHERE kp.character_id = p.character_id AND kp.alliance_id IS NOT NULL AND date_trunc('month', k.kill_date) = p.m) AS in_alliance
    FROM pick p JOIN character_month_activity cma ON cma.character_id = p.character_id AND cma.month = p.m)
  SELECT base, count(*) AS players, round(avg(in_player_corporation::int), 4) AS in_player_corp, round(avg(in_alliance::int), 4) AS in_alliance,
         round(avg(flew_omega_ship::int), 4) AS flew_omega, round(avg(got_kill::int), 4) AS got_kill
  FROM a GROUP BY base, sort ORDER BY sort
) TO STDOUT WITH (FORMAT csv, HEADER);
