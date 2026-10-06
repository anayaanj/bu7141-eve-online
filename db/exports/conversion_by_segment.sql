-- Page 4: what turns a new player into a payer (first Omega-only ship), by first-month segment and area.
COPY (SELECT * FROM analysis.conversion_by_segment ORDER BY converted_within_12_months DESC) TO STDOUT WITH (FORMAT csv, HEADER);
