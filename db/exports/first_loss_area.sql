-- Act 2: where one-day newcomers lose their first ship to another player, by security band, and how many of those systems sit one gate from high-sec.
COPY (
  WITH fl AS (
    SELECT p.character_id, min(k.killmail_time) AS t
    FROM killmail_participant p JOIN killmail k USING (killmail_id)
    WHERE p.role = 'victim' AND p.character_id IN (SELECT character_id FROM analysis.casual_player WHERE first_month <= date '2026-05-01')
    GROUP BY 1),
  d AS (
    SELECT fl.character_id, k.solar_system_id, s.security_band
    FROM fl JOIN killmail_participant pv ON pv.character_id = fl.character_id AND pv.role = 'victim'
    JOIN killmail k ON k.killmail_id = pv.killmail_id AND k.killmail_time = fl.t
    JOIN solar_system s ON s.solar_system_id = k.solar_system_id
    WHERE EXISTS (SELECT 1 FROM killmail_participant a WHERE a.killmail_id = k.killmail_id AND a.role = 'attacker' AND a.character_id IS NOT NULL)),
  border AS (
    SELECT DISTINCT l.from_solar_system_id AS solar_system_id FROM stargate_link l
    JOIN solar_system a ON a.solar_system_id = l.from_solar_system_id JOIN solar_system b ON b.solar_system_id = l.to_solar_system_id
    WHERE a.security_band <> 'High Sec' AND b.security_band = 'High Sec')
  SELECT security_band, count(*) AS players, round(count(*)::numeric / sum(count(*)) OVER (), 4) AS share,
         round(avg((solar_system_id IN (SELECT solar_system_id FROM border))::int), 4) AS share_one_gate_from_highsec
  FROM d GROUP BY 1 ORDER BY 2 DESC
) TO STDOUT WITH (FORMAT csv, HEADER);
