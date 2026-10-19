-- Act 1: the largest battles of Jan 2024 - Aug 2026 by value destroyed, for the battle map.
-- Dollars: ISK destroyed / that month's PLEX price (ISK, volume-weighted) x $24.99 / 500 (the PLEX 500 pack). An estimate.
COPY (
  WITH victim AS (
    SELECT k.battle_id, count(*) AS ships_destroyed, sum(t.mean_isk_value) AS isk_destroyed
    FROM killmail k
    JOIN killmail_participant p ON p.killmail_id = k.killmail_id AND p.role = 'victim'
    JOIN item_type t ON t.type_id = p.ship_type_id
    WHERE k.battle_id IS NOT NULL
    GROUP BY 1
  ), plex AS (
    SELECT date_trunc('month', date)::date AS month, sum(average_price * volume) / sum(volume) AS plex_isk
    FROM market_history_daily WHERE type_id = 44992 GROUP BY 1
  )
  SELECT b.battle_date, s.solar_system_name, s.security_band, s.map_x, s.map_y,
         b.pilots, bp.peak_hour_pilots, v.ships_destroyed,
         round(v.isk_destroyed) AS isk_destroyed,
         round(v.isk_destroyed / x.plex_isk * 24.99 / 500) AS usd_estimate
  FROM battle b
  JOIN victim v USING (battle_id)
  JOIN solar_system s USING (solar_system_id)
  LEFT JOIN analysis.battle_peak bp USING (battle_id)
  LEFT JOIN plex x ON x.month = date_trunc('month', b.battle_date)::date
  ORDER BY v.isk_destroyed DESC
  LIMIT 25
) TO STDOUT WITH (FORMAT csv, HEADER);
