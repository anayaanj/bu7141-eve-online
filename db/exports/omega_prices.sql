-- Page 4: Omega plan prices over time (USD), with the price per month.
COPY (
  SELECT p.plan_name, p.billing_cycle_months, pp.effective_date, pp.list_price,
         round(pp.list_price / p.billing_cycle_months, 2) AS price_per_month
  FROM plan_price pp JOIN plan p USING (plan_id)
  WHERE p.product_type = 'subscription' ORDER BY p.billing_cycle_months, pp.effective_date
) TO STDOUT WITH (FORMAT csv, HEADER);
