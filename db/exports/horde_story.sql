-- Act 3 natural experiment on one timeline: systems Pandemic Horde held (first of month) and the month-3 retention of
-- newcomers who joined that month, Horde vs other alliances.
COPY (
  WITH terr AS (SELECT date AS month, count(*) AS horde_systems FROM sovereignty_daily
                WHERE alliance_id = 99005338 AND extract(day FROM date) = 1 GROUP BY 1),
  ret AS (
    SELECT x.first_month AS month,
           count(*) FILTER (WHERE x.alliance_id = 99005338) AS horde_newcomers,
           round(count(a3.character_id) FILTER (WHERE x.alliance_id = 99005338)::numeric / nullif(count(*) FILTER (WHERE x.alliance_id = 99005338), 0), 4) AS horde_retention_month_3,
           round(count(a3.character_id) FILTER (WHERE x.alliance_id <> 99005338)::numeric / nullif(count(*) FILTER (WHERE x.alliance_id <> 99005338), 0), 4) AS other_alliances_retention_month_3
    FROM analysis.new_player_alliance x
    LEFT JOIN analysis.new_player_activity a3 ON a3.character_id = x.character_id AND a3.k = 3
    WHERE x.alliance_id IS NOT NULL AND x.first_month <= date '2026-05-01' GROUP BY 1)
  SELECT m.month::date, coalesce(t.horde_systems, 0) AS horde_systems, r.horde_newcomers, r.horde_retention_month_3, r.other_alliances_retention_month_3
  FROM generate_series(date '2024-01-01', date '2026-08-01', interval '1 month') m(month)
  LEFT JOIN terr t ON t.month = m.month LEFT JOIN ret r ON r.month = m.month
  ORDER BY 1
) TO STDOUT WITH (FORMAT csv, HEADER);
