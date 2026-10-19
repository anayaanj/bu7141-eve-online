-- Act 5: does it matter how fast a newcomer joins a player corporation? Newcomers still active at month 2, by the month they first
-- appeared in a player corporation (0 = their first month), and the share still active at month 6. Fair cut: everyone here survived to month 2.
COPY (
  WITH n AS (SELECT character_id, first_month FROM analysis.new_player WHERE first_month + interval '6 month' <= date '2026-08-01'),
  act2 AS (SELECT n.* FROM n JOIN character_month_activity a ON a.character_id = n.character_id AND a.month = (n.first_month + interval '2 month')::date),
  joined AS (
    SELECT a2.character_id, a2.first_month,
           min((date_part('year', a.month) - date_part('year', a2.first_month)) * 12 + date_part('month', a.month) - date_part('month', a2.first_month))::int AS joined_k
    FROM act2 a2 JOIN character_month_activity a ON a.character_id = a2.character_id AND a.in_player_corporation AND a.month <= (a2.first_month + interval '2 month')::date
    GROUP BY 1, 2)
  SELECT CASE WHEN j.joined_k IS NULL THEN 'Not by month 2' ELSE 'Month ' || j.joined_k END AS joined_a_player_corp, coalesce(j.joined_k, 9) AS sort, count(*) AS players,
         round(avg((EXISTS (SELECT 1 FROM character_month_activity a6 WHERE a6.character_id = a2.character_id AND a6.month = (a2.first_month + interval '6 month')::date))::int), 4) AS active_month_6
  FROM act2 a2 LEFT JOIN joined j USING (character_id, first_month) GROUP BY 1, 2 ORDER BY 2
) TO STDOUT WITH (FORMAT csv, HEADER);
