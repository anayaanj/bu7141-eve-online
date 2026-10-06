-- Act 5 what-if: inputs for a Tableau parameter "% of newcomers moved into a group".
-- Extra first-year revenue = share moved x newcomers per year x (value in a group - value alone). Estimates (2025 ARPU).
COPY (
  WITH v AS (SELECT segment, ltv_first_year FROM analysis.newcomer_value),
  u AS (SELECT * FROM analysis.unit_economics WHERE year = 2025),
  neither_share AS (
    SELECT avg((segment = 'Neither')::int) AS share FROM analysis.new_player_segment
    WHERE segment IN ('Neither', 'Joined a corp and got a kill', 'Joined a corp only', 'Got a kill only'))
  SELECT 'Engaged newcomers who play alone, moved into a group with a win' AS scenario,
         round(u.engaged * (SELECT share FROM neither_share)) AS newcomers_per_year,
         (SELECT ltv_first_year FROM v WHERE segment = 'Neither') AS value_alone,
         (SELECT ltv_first_year FROM v WHERE segment = 'Joined a corp and got a kill') AS value_in_group,
         u.arr, u.cac_per_engaged_newcomer
  FROM u
  UNION ALL
  SELECT 'Casual newcomers in the starter corporation, moved into a mid-sized corporation',
         round((SELECT count(*) FROM analysis.casual_player WHERE first_corp_size = 'NPC starter corp'
                AND first_month BETWEEN date '2025-01-01' AND date '2025-12-01')),
         (SELECT ltv_first_year FROM v WHERE segment = 'Casual, starter corporation'),
         (SELECT ltv_first_year FROM v WHERE segment = 'Casual, mid-sized corporation (51-1,000)'),
         u.arr, u.cac_per_engaged_newcomer
  FROM u
) TO STDOUT WITH (FORMAT csv, HEADER);
