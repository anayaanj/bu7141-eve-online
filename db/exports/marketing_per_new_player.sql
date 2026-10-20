-- Act 3: marketing per new player by quarter, 2024-2025. CCP reports marketing once a year, so each quarter gets a quarter of it.
-- New player = engaged newcomer (seen fighting or trading in their first month), as in unit_economics.
COPY (
  WITH n AS (
    SELECT date_trunc('quarter', first_month)::date AS quarter, count(*) AS new_players
    FROM analysis.new_player
    WHERE first_month >= date '2024-01-01' AND first_month < date '2026-01-01'
    GROUP BY 1)
  SELECT n.quarter, n.new_players, round(u.marketing / 4.0) AS marketing,
         round(u.marketing / 4.0 / n.new_players, 2) AS marketing_per_new_player,
         u.cac_per_engaged_newcomer AS year_average
  FROM n JOIN analysis.unit_economics u ON u.year = extract(year FROM n.quarter)
  ORDER BY n.quarter
) TO STDOUT WITH (FORMAT csv, HEADER);
