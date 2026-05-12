#!/bin/bash
# Creates the fishers table and imports backend/incoming_data/fishers_nhs.csv.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
CSV_PATH="$REPO_ROOT/backend/incoming_data/fishers_nhs.csv"
SQL_FILE="$SCRIPT_DIR/006_import_fishers_nhs.sql"

psql_run() {
    PGPASSWORD=extramild20 psql -h localhost -p 5432 -U postgres -d ngonye_rap "$@"
}

echo "==> Importing $CSV_PATH into fishers table..."

sed "s|-- <<COPY_CMD>>|\\\\COPY fishers_staging FROM '$CSV_PATH' CSV HEADER;|" \
    "$SQL_FILE" | psql_run -f -

ROW_COUNT=$(psql_run -t -A -c "SELECT COUNT(*) FROM fishers")
echo "==> Done. $ROW_COUNT rows in fishers table."
