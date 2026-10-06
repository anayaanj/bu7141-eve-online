-- Acts 2 and 3: casual new players (seen on one day). What their day looked like, and the share still seen 3 months later.
COPY (
  WITH c AS (SELECT * FROM analysis.casual_player WHERE first_month <= date '2026-05-01'),
  dims AS (
    SELECT character_id, active_month_3, 'What happened' AS dimension,
           CASE WHEN got_kill AND NOT (killed_by_player OR killed_by_npc) THEN 'Got a kill and survived'
                WHEN got_kill THEN 'Got a kill and died'
                WHEN killed_by_player THEN 'Killed by another player'
                WHEN killed_by_npc THEN 'Killed by the computer (NPCs)'
                ELSE 'Only traded' END AS value FROM c
    UNION ALL SELECT character_id, active_month_3, 'Killed by a veteran',
           CASE WHEN killed_by_veteran THEN 'Yes' WHEN killed_by_player THEN 'No, by a newer player' ELSE 'Not killed by a player' END FROM c
    UNION ALL SELECT character_id, active_month_3, 'Killed in their first week',
           CASE WHEN killed_in_first_week THEN 'Yes' ELSE 'No' END FROM c
    UNION ALL SELECT character_id, active_month_3, 'Killed by a player in a starter system',
           CASE WHEN killed_in_starter_system THEN 'Yes' WHEN killed_by_player THEN 'No, elsewhere' ELSE 'Not killed by a player' END FROM c
    UNION ALL SELECT character_id, active_month_3, 'Lost their escape pod',
           CASE WHEN lost_pod THEN 'Yes' ELSE 'No' END FROM c
    UNION ALL SELECT character_id, active_month_3, 'Where they were', coalesce(main_area, 'Trading only') FROM c
    UNION ALL SELECT character_id, active_month_3, 'Their corporation', coalesce(first_corp_size, 'Unknown (trading only)') FROM c
  )
  SELECT dimension, value, count(*) AS players,
         round(count(*)::numeric / sum(count(*)) OVER (PARTITION BY dimension), 4) AS share,
         round(avg(active_month_3::int), 4) AS retention_month_3
  FROM dims GROUP BY 1, 2 ORDER BY 1, players DESC
) TO STDOUT WITH (FORMAT csv, HEADER);
