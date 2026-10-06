-- Page 2 (robustness panel): the corporation effect measured on contracts only, which fleet killmails can't inflate.
COPY (SELECT * FROM analysis.robustness_contracts_only ORDER BY k, segment) TO STDOUT WITH (FORMAT csv, HEADER);
