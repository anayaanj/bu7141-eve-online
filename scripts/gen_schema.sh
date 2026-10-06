#!/bin/sh
# Regenerates db/schema.sql from docs/erd.dbml. Run after every ERD change.
set -e
cd "$(dirname "$0")/.."
npx -y -p @dbml/cli dbml2sql docs/erd.dbml --postgres -o db/schema.sql
sed -i.bak '/^-- Generated at/d' db/schema.sql && rm db/schema.sql.bak
rm -f dbml-error.log
