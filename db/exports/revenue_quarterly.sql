-- Page 4: EVE revenue by quarter, and MRR (a third of the quarter). Pearl Abyss reports KRW; USD is calculated at the quarter's average FRED rate.
COPY (
  SELECT f.period_start AS quarter_start, f.amount AS eve_revenue_krw,
         round(f.amount / avg(x.rate)) AS eve_revenue_usd, round(f.amount / avg(x.rate) / 3) AS mrr_usd, round(avg(x.rate), 2) AS krw_per_usd
  FROM financial_metric f
  JOIN fx_rate x ON x.currency_pair = 'KRW/USD' AND x.date BETWEEN f.period_start AND f.period_end
  WHERE f.metric = 'eve_revenue'
  GROUP BY f.period_start, f.amount ORDER BY 1
) TO STDOUT WITH (FORMAT csv, HEADER);
