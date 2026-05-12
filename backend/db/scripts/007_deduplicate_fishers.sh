#!/bin/bash
# Merges confirmed duplicate fisher records into their matching existing person records.
# Reads accepted pairs from backend/incoming_data/fisher_duplicate_candidates.csv.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
CSV_PATH="$REPO_ROOT/backend/incoming_data/fisher_duplicate_candidates.csv"
SQL_FILE="$SCRIPT_DIR/007_deduplicate_fishers.sql"

psql_run() {
    PGPASSWORD=extramild20 psql -h localhost -p 5432 -U postgres -d ngonye_rap "$@"
}

echo "==> Running fisher deduplication..."

sed "s|-- <<COPY_CMD>>|\\\\COPY dup_staging FROM '$CSV_PATH' CSV HEADER;|" \
    "$SQL_FILE" | psql_run -f -

echo ""
echo "==> Verification:"
psql_run -c "SELECT COUNT(*) AS fishers_in_person  FROM person  WHERE fisher = true;"
psql_run -c "SELECT COUNT(*) AS fishers_table_rows  FROM fishers;"
psql_run -c "
SELECT COUNT(*) AS broken_fk
FROM fishers f
LEFT JOIN person p ON f.person_id = p.person_id
WHERE p.person_id IS NULL;"
