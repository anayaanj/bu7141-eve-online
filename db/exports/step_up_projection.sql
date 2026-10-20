-- Act 4: what moving newcomers up a step is worth. A share p of the "Alone" and "In a corp" newcomers is moved up to
-- the alliance step and takes on its first-year revenue and year-later retention; everyone else is unchanged.
-- Net = 2025's engaged newcomers × (first-year revenue per newcomer − the $117 it cost to bring one in). Estimates:
-- revenue is an upper bound, and it assumes moved newcomers behave like those who reached the alliance step themselves.
COPY (
  WITH s AS (
    SELECT s.step_sort, s.character_id
    FROM analysis.new_player_step s WHERE s.first_month <= date '2025-08-01'),
  a AS (
    SELECT s.character_id, count(*) FILTER (WHERE a.k BETWEEN 0 AND 11) AS months, bool_or(a.k = 12) AS year_later
    FROM s JOIN analysis.new_player_activity a USING (character_id) GROUP BY 1),
  ue AS (SELECT arpu_month, cac_per_engaged_newcomer AS cac, engaged FROM analysis.unit_economics WHERE year = 2025),
  st AS (
    SELECT s.step_sort, count(*)::numeric / sum(count(*)) OVER () AS share,
           avg(coalesce(a.months, 0)) * (SELECT arpu_month FROM ue) AS revenue,
           avg(coalesce(a.year_later, false)::int) AS year_later
    FROM s LEFT JOIN a USING (character_id) GROUP BY s.step_sort),
  m AS (
    SELECT sum(share * revenue) AS revenue_now, sum(share * year_later) AS year_later_now,
           sum(share * ((SELECT revenue FROM st WHERE step_sort = 3) - revenue)) FILTER (WHERE step_sort <= 2) AS revenue_gain,
           sum(share * ((SELECT year_later FROM st WHERE step_sort = 3) - year_later)) FILTER (WHERE step_sort <= 2) AS year_later_gain
    FROM st)
  SELECT round(p.p / 100.0, 2) AS share_moved,
         round(ue.engaged * (m.revenue_now + p.p / 100.0 * m.revenue_gain - ue.cac)) AS net_year_one,
         round(ue.engaged * p.p / 100.0 * m.revenue_gain) AS extra_revenue,
         round(m.year_later_now + p.p / 100.0 * m.year_later_gain, 4) AS still_playing_year_later,
         round((ue.cac - m.revenue_now) / m.revenue_gain, 3) AS break_even_share
  FROM generate_series(0, 100, 5) AS p(p) CROSS JOIN m CROSS JOIN ue
  ORDER BY p.p
) TO STDOUT WITH (FORMAT csv, HEADER);
