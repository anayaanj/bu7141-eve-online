-- Act 3 dumbbell: casual newcomers seen again at month 3, alone vs in a group or with a win.
COPY (
  SELECT * FROM (VALUES
    ('Corporation', 'Starter corporation', (SELECT round(avg(active_month_3::int), 4) FROM analysis.casual_player WHERE first_corp_size = 'NPC starter corp' AND first_month <= '2026-05-01'),
                    'Mid-sized player corporation (201-1,000)', (SELECT round(avg(active_month_3::int), 4) FROM analysis.casual_player WHERE first_corp_size = '201-1,000 members' AND first_month <= '2026-05-01')),
    ('Where', 'High-sec', (SELECT round(avg(active_month_3::int), 4) FROM analysis.casual_player WHERE main_area = 'High Sec' AND first_month <= '2026-05-01'),
              'Player-held null-sec', (SELECT round(avg(active_month_3::int), 4) FROM analysis.casual_player WHERE main_area = 'Null Sec (Sov)' AND first_month <= '2026-05-01')),
    ('First fight', 'Killed by another player', (SELECT round(avg(active_month_3::int), 4) FROM analysis.casual_player WHERE killed_by_player AND NOT got_kill AND first_month <= '2026-05-01'),
                    'Got a kill and survived', (SELECT round(avg(active_month_3::int), 4) FROM analysis.casual_player WHERE got_kill AND NOT (killed_by_player OR killed_by_npc) AND first_month <= '2026-05-01'))
  ) AS t(pair, alone, alone_retention_month_3, together, together_retention_month_3)
) TO STDOUT WITH (FORMAT csv, HEADER);
