-- Act 3 (natural experiment): Pandemic Horde, a big alliance for new players, lost almost all its space in Nov-Dec 2025.
-- 3-month retention of its newcomers vs newcomers in other alliances, by first month.
COPY (
  SELECT x.first_month,
         CASE WHEN x.alliance_id = 99005338 THEN 'Pandemic Horde' ELSE 'Other alliances' END AS alliance,
         count(*) AS new_players,
         round(count(a3.character_id)::numeric / count(*), 4) AS retention_month_3
  FROM analysis.new_player_alliance x
  LEFT JOIN analysis.new_player_activity a3 ON a3.character_id = x.character_id AND a3.k = 3
  WHERE x.alliance_id IS NOT NULL AND x.first_month <= date '2026-05-01'
  GROUP BY 1, 2 ORDER BY 1, 2
) TO STDOUT WITH (FORMAT csv, HEADER);
