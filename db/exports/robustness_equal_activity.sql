-- Page 2 (robustness panel): the corporation effect among players who were equally active in their first month.
COPY (SELECT * FROM analysis.robustness_equal_activity ORDER BY 1, 2) TO STDOUT WITH (FORMAT csv, HEADER);
