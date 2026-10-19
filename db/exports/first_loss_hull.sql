-- Act 2: what one-day newcomers lose first, by hull class. One row per class, with the share and the month-3 return.
COPY (
  WITH fl AS (
    SELECT p.character_id, min(k.killmail_time) AS t
    FROM killmail_participant p JOIN killmail k USING (killmail_id)
    WHERE p.role = 'victim' AND p.character_id IN (SELECT character_id FROM analysis.casual_player WHERE first_month <= date '2026-05-01')
    GROUP BY 1),
  d AS (
    SELECT fl.character_id, g.group_name, c.active_month_3
    FROM fl JOIN killmail_participant pv ON pv.character_id = fl.character_id AND pv.role = 'victim'
    JOIN killmail k ON k.killmail_id = pv.killmail_id AND k.killmail_time = fl.t
    JOIN item_type it ON it.type_id = pv.ship_type_id JOIN item_group g ON g.group_id = it.group_id
    JOIN analysis.casual_player c ON c.character_id = fl.character_id)
  SELECT CASE WHEN group_name IN ('Corvette', 'Frigate', 'Destroyer', 'Shuttle', 'Cruiser', 'Capsule', 'Mining Barge') THEN group_name ELSE 'Other' END AS hull,
         CASE WHEN group_name IN ('Corvette', 'Frigate', 'Destroyer', 'Shuttle') THEN 'Starter class' WHEN group_name = 'Capsule' THEN 'Capsule' ELSE 'Bigger ship' END AS kind,
         count(*) AS players, round(count(*)::numeric / sum(count(*)) OVER (), 4) AS share, round(avg(active_month_3::int), 4) AS retention_month_3
  FROM d GROUP BY 1, 2 ORDER BY 3 DESC
) TO STDOUT WITH (FORMAT csv, HEADER);
