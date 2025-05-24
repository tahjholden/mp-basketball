#!/usr/bin/env bash
set -euo pipefail

DB_URL="${TEST_DB_URL:-postgres://postgres@localhost/postgres}"

if ! command -v psql >/dev/null; then
  echo "psql command not found" >&2
  exit 1
fi

for file in supabase/migrations/*.sql; do
  echo "Validating $file"
  psql "$DB_URL" -v ON_ERROR_STOP=1 <<EOSQL
BEGIN;
\i $file
ROLLBACK;
EOSQL
done
