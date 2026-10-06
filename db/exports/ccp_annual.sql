-- Page 4: CCP ehf. audited annual figures (USD), one row per year and metric (geography for revenue by region).
COPY (
  SELECT extract(year FROM period_start)::int AS year, metric, coalesce(geography, '') AS geography, amount
  FROM financial_metric WHERE entity = 'CCP ehf.' ORDER BY 1, 2, 3
) TO STDOUT WITH (FORMAT csv, HEADER);
