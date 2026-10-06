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
