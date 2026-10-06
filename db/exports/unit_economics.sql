-- Page 4: MRR / ARR, ARPU and CAC by year (estimates from CCP's audited accounts; shade as estimates).
COPY (SELECT * FROM analysis.unit_economics ORDER BY year) TO STDOUT WITH (FORMAT csv, HEADER);
