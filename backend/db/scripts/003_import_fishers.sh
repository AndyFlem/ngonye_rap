#!/bin/bash
# Imports backend/incoming_data/fishers.csv into the person table,
# then writes the generated person_id back into the CSV.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
CSV_PATH="$REPO_ROOT/backend/incoming_data/fishers.csv"
SQL_FILE="$SCRIPT_DIR/003_import_fishers.sql"
IDS_TMP="$(mktemp /tmp/fishers_ids.XXXXXX.csv)"

trap 'rm -f "$IDS_TMP"' EXIT

psql_run() {
    PGPASSWORD=extramild20 psql -h localhost -p 5432 -U postgres -d ngonye_rap "$@"
}

echo "==> Importing $CSV_PATH into person table..."

# psql \COPY does not support variable interpolation, so we inject the path via
# sed before piping the SQL to psql.
sed "s|-- <<COPY_CMD>>|\\\\COPY fishers_staging FROM '$CSV_PATH' CSV HEADER;|" \
    "$SQL_FILE" | psql_run -f -

echo "==> Fetching person IDs for imported fishers..."
psql_run -t -A -F',' \
    -c "SELECT nhs, person_id FROM person WHERE fisher = true AND nhs IS NOT NULL ORDER BY nhs" \
    > "$IDS_TMP"

ROW_COUNT=$(wc -l < "$IDS_TMP" | tr -d ' ')
echo "==> Got $ROW_COUNT person IDs"

echo "==> Writing person_id column back to $CSV_PATH..."
python3 - "$CSV_PATH" "$IDS_TMP" << 'PYEOF'
import csv, sys

csv_path, ids_path = sys.argv[1], sys.argv[2]

id_map = {}
with open(ids_path) as f:
    for line in f:
        line = line.strip()
        if line:
            nhs, pid = line.split(',', 1)
            id_map[nhs] = pid

rows = []
with open(csv_path, newline='') as f:
    reader = csv.DictReader(f)
    fieldnames = list(reader.fieldnames)
    if 'person_id' not in fieldnames:
        fieldnames.append('person_id')
    for row in reader:
        row['person_id'] = id_map.get(row['nhs'].strip(), '')
        rows.append(row)

with open(csv_path, 'w', newline='') as f:
    writer = csv.DictWriter(f, fieldnames=fieldnames)
    writer.writeheader()
    writer.writerows(rows)

matched = sum(1 for r in rows if r['person_id'])
print(f"Mapped {matched}/{len(rows)} rows with person_id")
PYEOF

echo "==> Done. fishers.csv updated with person_id column."
