#!/bin/sh
# Loads data/clean/*.csv.gz (from scripts/transform.py) into the local PostgreSQL (docker compose).
# Rebuilds the schema from db/schema.sql, bulk-loads every table that has a CSV, then adds the
# foreign keys and indexes: adding a foreign key checks every row, so integrity is enforced.
# Usage: ./scripts/load.sh
set -e
cd "$(dirname "$0")/.."
CLEAN=data/clean
PSQL="docker compose exec -T db psql -v ON_ERROR_STOP=1 -q -U eve -d eve"

# Tables in dependency order (parents before children)
TABLES="source_document calendar_date region constellation solar_system stargate_link item_category item_group item_type
alliance corporation player_character character_signup_month war battle contract contract_item character_month_activity
players_online_daily sov_campaign sovereignty_daily game_event market_history_daily fx_rate economy_daily interest_metric
steam_review forum_topic forum_post plan plan_price financial_metric benchmark_metric"

echo "== Rebuilding schema (tables only)"
echo "DROP SCHEMA public CASCADE; CREATE SCHEMA public;" | $PSQL
grep -v -E '^(ALTER TABLE .* FOREIGN KEY|CREATE INDEX)' db/schema.sql | $PSQL

copy() {  # copy <table> <columns> < csv on stdin (no header)
  $PSQL -c "\copy $1 ($2) FROM STDIN WITH (FORMAT csv)"
}

for t in $TABLES; do
  f="$CLEAN/$t.csv.gz"
  [ -f "$f" ] || { echo "-- $t: no CSV yet, skipped"; continue; }
  cols=$(gunzip -c "$f" | head -1)
  echo "== $t"
  gunzip -c "$f" | tail -n +2 | copy "$t" "$cols"
done

# Killmails come as one file per day, without headers
if [ -d "$CLEAN/_work/killmail_parts" ]; then
  echo "== killmail"
  for f in "$CLEAN"/_work/killmail_parts/killmail_2*.csv.gz; do gunzip -c "$f"; done |
    copy killmail "killmail_id, killmail_time, kill_date, solar_system_id, war_id, battle_id, attacker_count"
  echo "== killmail_participant"
  for f in "$CLEAN"/_work/killmail_parts/killmail_participant_*.csv.gz; do gunzip -c "$f"; done |
    copy killmail_participant "killmail_id, participant_no, role, character_id, corporation_id, alliance_id, ship_type_id, weapon_type_id, damage, final_blow"
  echo "== killmail.battle_id"
  { echo "CREATE TEMP TABLE kb (killmail_id bigint PRIMARY KEY, battle_id int);"
    echo "COPY kb FROM STDIN WITH (FORMAT csv);"
    gunzip -c "$CLEAN/killmail_battle.csv.gz" | tail -n +2
    echo '\.'
    echo "UPDATE killmail k SET battle_id = kb.battle_id FROM kb WHERE k.killmail_id = kb.killmail_id;"
  } | $PSQL
fi

echo "== Foreign keys and indexes (checks every row)"
grep -E '^(ALTER TABLE .* FOREIGN KEY|CREATE INDEX)' db/schema.sql | $PSQL
echo "ANALYZE;" | $PSQL

echo "== Row counts (estimates after ANALYZE)"
$PSQL -c "SELECT relname AS table, n_live_tup AS rows FROM pg_stat_user_tables ORDER BY relname"
