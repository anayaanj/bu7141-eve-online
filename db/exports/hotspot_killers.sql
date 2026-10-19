-- Act 2: who kills one-day newcomers, at the five deadliest systems and overall: how many attackers, how old the killer's character is,
-- and how concentrated the kills are. Final blow = the attacker who landed the killing shot.
COPY (
  WITH fl AS (
    SELECT p.character_id, min(k.killmail_time) AS t
    FROM killmail_participant p JOIN killmail k USING (killmail_id)
    WHERE p.role = 'victim' AND p.character_id IN (SELECT character_id FROM analysis.casual_player WHERE first_month <= date '2026-05-01')
    GROUP BY 1),
  d AS (
    SELECT fl.character_id, k.killmail_id, k.attacker_count, s.solar_system_name,
           (SELECT pa.character_id FROM killmail_participant pa WHERE pa.killmail_id = k.killmail_id AND pa.role = 'attacker' AND pa.final_blow LIMIT 1) AS killer_id
    FROM fl JOIN killmail_participant pv ON pv.character_id = fl.character_id AND pv.role = 'victim'
    JOIN killmail k ON k.killmail_id = pv.killmail_id AND k.killmail_time = fl.t
    JOIN solar_system s ON s.solar_system_id = k.solar_system_id
    WHERE EXISTS (SELECT 1 FROM killmail_participant a WHERE a.killmail_id = k.killmail_id AND a.role = 'attacker' AND a.character_id IS NOT NULL)),
  dk AS (
    SELECT d.*, pc.signup_date AS killer_signup, (pc.signup_date IS NULL OR pc.signup_date < date '2024-01-01') AS killer_veteran
    FROM d LEFT JOIN player_character pc ON pc.character_id = d.killer_id),
  grp AS (
    SELECT CASE WHEN solar_system_name IN ('Ahbazon', 'Tama', 'Jita', 'Uitra', 'Ami') THEN solar_system_name ELSE 'All systems' END AS place, * FROM dk
    UNION ALL SELECT 'All systems', * FROM dk WHERE solar_system_name IN ('Ahbazon', 'Tama', 'Jita', 'Uitra', 'Ami')),
  per AS (SELECT place, killer_id, count(*) AS kills FROM grp WHERE killer_id IS NOT NULL GROUP BY 1, 2),
  conc AS (SELECT place, count(*) AS killers, max(kills) AS most_by_one,
                  round(sum(kills) FILTER (WHERE rn <= 20)::numeric / sum(kills), 4) AS share_top20
           FROM (SELECT *, row_number() OVER (PARTITION BY place ORDER BY kills DESC) AS rn FROM per) r GROUP BY 1)
  SELECT g.place, count(*) AS newcomers_killed,
         round(avg((attacker_count = 1)::int), 4) AS share_solo, round(avg((attacker_count >= 6)::int), 4) AS share_six_or_more,
         round(avg(killer_veteran::int), 4) AS share_veteran_final_blow,
         round((percentile_cont(0.5) WITHIN GROUP (ORDER BY (date '2026-08-15' - killer_signup) / 365.25))::numeric, 1) AS median_killer_age_years,
         c.killers, c.share_top20, c.most_by_one
  FROM grp g JOIN conc c USING (place)
  GROUP BY 1, c.killers, c.share_top20, c.most_by_one ORDER BY 2 DESC
) TO STDOUT WITH (FORMAT csv, HEADER);
