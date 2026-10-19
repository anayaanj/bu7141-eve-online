-- Act 2: newcomers' in-game economy in their first month, and how many in each band are still playing a year later.
-- Traded: price + reward of the contracts they issued. Lost: CCP's average value of the hulls they lost (fittings not included).
-- Cohorts with 12 months of follow-up (first month <= 2025-08-01).
COPY (
  WITH n AS (
    SELECT n.character_id, n.first_month, a12.character_id IS NOT NULL AS year_later
    FROM analysis.new_player n
    LEFT JOIN analysis.new_player_activity a12 ON a12.character_id = n.character_id AND a12.k = 12
    WHERE n.first_month <= date '2025-08-01'),
  traded AS (
    SELECT n.character_id, sum(coalesce(c.price, 0) + coalesce(c.reward, 0)) AS isk
    FROM n JOIN contract c ON c.issuer_character_id = n.character_id
     AND c.issued_date >= n.first_month AND c.issued_date < n.first_month + interval '1 month'
    GROUP BY 1),
  lost AS (
    SELECT n.character_id, sum(coalesce(it.mean_isk_value, 0)) AS isk
    FROM n
    JOIN killmail_participant pv ON pv.character_id = n.character_id AND pv.role = 'victim'
    JOIN killmail k ON k.killmail_id = pv.killmail_id
     AND k.kill_date >= n.first_month AND k.kill_date < n.first_month + interval '1 month'
    LEFT JOIN item_type it ON it.type_id = pv.ship_type_id
    GROUP BY 1),
  b AS (
    SELECT n.year_later,
           CASE WHEN t.isk IS NULL OR t.isk = 0 THEN 'None' WHEN t.isk < 1e7 THEN 'Under 10M'
                WHEN t.isk < 1e8 THEN '10M - 100M' WHEN t.isk < 1e9 THEN '100M - 1B' ELSE '1B+' END AS traded_band,
           CASE WHEN t.isk IS NULL OR t.isk = 0 THEN 1 WHEN t.isk < 1e7 THEN 2 WHEN t.isk < 1e8 THEN 3 WHEN t.isk < 1e9 THEN 4 ELSE 5 END AS traded_sort,
           CASE WHEN l.isk IS NULL THEN 'None' WHEN l.isk < 1e6 THEN 'Under 1M'
                WHEN l.isk < 1e7 THEN '1M - 10M' WHEN l.isk < 1e8 THEN '10M - 100M' ELSE '100M+' END AS lost_band,
           CASE WHEN l.isk IS NULL THEN 1 WHEN l.isk < 1e6 THEN 2 WHEN l.isk < 1e7 THEN 3 WHEN l.isk < 1e8 THEN 4 ELSE 5 END AS lost_sort
    FROM n LEFT JOIN traded t USING (character_id) LEFT JOIN lost l USING (character_id))
  SELECT 'ISK traded' AS measure, traded_sort AS sort, traded_band AS band, count(*) AS newcomers,
         round(count(*)::numeric / sum(count(*)) OVER (), 4) AS share, round(avg(year_later::int), 4) AS still_playing
  FROM b GROUP BY 1, 2, 3
  UNION ALL
  SELECT 'Ships lost (hull value)', lost_sort, lost_band, count(*),
         round(count(*)::numeric / sum(count(*)) OVER (), 4), round(avg(year_later::int), 4)
  FROM b GROUP BY 1, 2, 3
  ORDER BY 1, 2
) TO STDOUT WITH (FORMAT csv, HEADER);
