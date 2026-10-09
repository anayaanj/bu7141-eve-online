-- Page 4: first-year value (LTV) of a newcomer by group vs what it cost to acquire them (CAC, 2025).
COPY (SELECT * FROM analysis.newcomer_value ORDER BY ltv_first_year) TO STDOUT WITH (FORMAT csv, HEADER);
