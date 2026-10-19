#!/bin/sh
# Writes one CSV per dashboard view (db/exports/<name>.sql) to data/exports/<name>.csv, for Tableau Public.
# Run after scripts/load.sh and db/analysis.sql.  Usage: ./scripts/export.sh
set -e
cd "$(dirname "$0")/.."
mkdir -p data/exports
for f in db/exports/*.sql; do
  name=$(basename "$f" .sql)
  docker compose exec -T db psql -v ON_ERROR_STOP=1 -q -U eve -d eve -f - < "$f" > "data/exports/$name.csv"
  echo "$name: $(($(wc -l < "data/exports/$name.csv") - 1)) rows"
done
# Hand-collected turning points for the 20-year timeline (no database table; copied as is so make_workbook.py builds an extract)
cp data/reference/great_wars.csv data/exports/great_wars.csv
echo "great_wars: $(($(wc -l < data/exports/great_wars.csv) - 1)) rows"
cp data/reference/famous_battles.csv data/exports/famous_battles.csv
echo "famous_battles: $(($(wc -l < data/exports/famous_battles.csv) - 1)) rows"
