"""Monthly cohort retention in the WoWAH dataset, using the same definition as our EVE analysis:
share of characters first seen in month M that are active again in month M+k (cohorts Feb 2006 - Dec 2007).
Needs: pip install duckdb. Output feeds the WoWAH rows of data/reference/benchmarks.csv."""
import duckdb

SQL = """
with m as (select distinct player_id, date_trunc('month', datetime) as mo from 'data/raw/benchmarks/wowah_full.parquet'),
f as (select player_id, min(mo) as cohort from m group by 1),
c as (select f.cohort, datediff('month', f.cohort, m.mo) as k, count(*) as n from m join f using (player_id) group by 1, 2),
base as (select cohort, n as size from c where k = 0)
select k, round(avg(c.n * 1.0 / base.size), 4) as retention, count(*) as cohorts
from c join base using (cohort)
where cohort between '2006-02-01' and '2007-12-01' and k in (1, 2, 3, 6, 12)
group by k order by k
"""

if __name__ == "__main__":
    for k, retention, cohorts in duckdb.sql(SQL).fetchall():
        print(f"month {k}: {retention:.1%} ({cohorts} cohorts)")
