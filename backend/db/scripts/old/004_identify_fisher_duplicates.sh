#!/bin/bash
# Runs the fisher duplicate detection query and writes results to CSV.
# Output: backend/incoming_data/fisher_duplicate_candidates.csv
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
SQL_FILE="$SCRIPT_DIR/004_identify_fisher_duplicates.sql"
OUT_CSV="$REPO_ROOT/backend/incoming_data/fisher_duplicate_candidates.csv"

psql_run() {
    PGPASSWORD=extramild20 psql -h localhost -p 5432 -U postgres -d ngonye_rap "$@"
}

echo "==> Running fisher duplicate detection..."

# Write header
echo "fisher_person_id,fisher_nhs,fisher_firstname,fisher_lastname,fisher_village_id,fisher_nrc,fisher_contact,existing_person_id,existing_pah,existing_firstname,existing_lastname,existing_village_id,existing_nrc,existing_contact,firstname_sim,lastname_sim,village_match,nrc_match,contact_match,match_score" \
    > "$OUT_CSV"

# Append data rows
psql_run -t -A -F',' -f "$SQL_FILE" >> "$OUT_CSV"

ROW_COUNT=$(tail -n +2 "$OUT_CSV" | grep -c . || true)
echo "==> Found $ROW_COUNT candidate duplicate pair(s)"
echo "==> Results written to $OUT_CSV"
