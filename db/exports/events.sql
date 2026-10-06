-- Event markers for every time chart: expansions, ownership and pricing events.
COPY (
  SELECT event_date, category, title FROM game_event
  WHERE category IN ('expansion', 'company', 'monetization') AND event_date >= date '2024-01-01'
  ORDER BY event_date
) TO STDOUT WITH (FORMAT csv, HEADER);
