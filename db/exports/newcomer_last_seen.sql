-- Act 1: when we lose the newcomers we can see. Time between the first and the last day we see each newcomer fight or
-- trade, within 13 months of their first month; those seen in month 12 count as still playing.
-- Cohorts with 12 months of follow-up (first month <= 2025-08-01). Last seen fighting or trading, not last login.
COPY (
  WITH n AS (SELECT character_id, first_month FROM analysis.new_player WHERE first_month <= date '2025-08-01'),
  d AS (
    SELECT n.character_id, k.kill_date AS date
    FROM n JOIN killmail_participant p USING (character_id) JOIN killmail k USING (killmail_id)
    WHERE k.kill_date < n.first_month + interval '13 month'
    UNION
    SELECT n.character_id, c.issued_date
    FROM n JOIN contract c ON c.issuer_character_id = n.character_id
    WHERE c.issued_date < n.first_month + interval '13 month'),
  s AS (SELECT character_id, max(date) - min(date) AS span FROM d GROUP BY 1),
  t AS (
    SELECT CASE WHEN a.character_id IS NOT NULL THEN 7
                WHEN coalesce(s.span, 0) = 0 THEN 1 WHEN s.span < 7 THEN 2 WHEN s.span < 30 THEN 3
                WHEN s.span < 90 THEN 4 WHEN s.span < 180 THEN 5 ELSE 6 END AS sort
    FROM n LEFT JOIN s USING (character_id)
    LEFT JOIN analysis.new_player_activity a ON a.character_id = n.character_id AND a.k = 12),
  b AS (
    SELECT sort, count(*) AS newcomers FROM t GROUP BY sort)
  SELECT b.sort,
         (ARRAY['Seen on one day only', 'Gone within the first week', 'Gone in weeks 2 to 4', 'Gone in months 2 to 3',
                'Gone in months 4 to 6', 'Gone in months 7 to 12', 'Still playing a year later'])[b.sort] AS last_seen,
         b.newcomers, round(b.newcomers::numeric / sum(b.newcomers) OVER (), 4) AS share,
         round(sum(b.newcomers) OVER (ORDER BY b.sort DESC)::numeric / sum(b.newcomers) OVER (), 4) AS share_still_around
  FROM b ORDER BY b.sort
) TO STDOUT WITH (FORMAT csv, HEADER);
