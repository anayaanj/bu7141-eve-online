-- Act 1: the largest alliances by players: distinct characters seen fighting under the alliance tag, Jan 2024 - Aug 2026,
-- plus one row for the other alliances that fought the three costliest battles (M2-XFE, B-R5RB, Atioth).
COPY (
  WITH per AS (SELECT a.alliance_name, count(DISTINCT p.character_id) AS players
               FROM killmail_participant p JOIN alliance a USING (alliance_id) GROUP BY 1)
  SELECT alliance_name, players, rank() OVER (ORDER BY players DESC) AS rank, 'alliance' AS kind FROM per
  WHERE alliance_name IN ('Goonswarm Federation', 'Fraternity.', 'Pandemic Horde')
  UNION ALL
  SELECT 'Other alliances in these battles', count(DISTINCT p.character_id), 4, 'other'
  FROM killmail_participant p JOIN alliance a USING (alliance_id)
  WHERE a.alliance_name IN ('The Initiative.', 'Dracarys.', 'Brave Collective', 'Test Alliance Please Ignore', 'Northern Coalition.', 'Pandemic Legion')
  ORDER BY 3
) TO STDOUT WITH (FORMAT csv, HEADER);
