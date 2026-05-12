-- Fisher import script.
-- Run via 003_import_fishers.sh which supplies the CSV path and updates the CSV with person_id.
--
-- To run manually, replace :csv_path with the absolute path to fishers.csv, e.g.:
--   \COPY fishers_staging FROM '/abs/path/to/fishers.csv' CSV HEADER;

\set ON_ERROR_STOP on

BEGIN;

CREATE TEMP TABLE fishers_staging (
    nhs           varchar(10),
    village_id    text,
    firstname     text,
    lastname      text,
    gender        text,
    year_of_birth text,
    nrc           text,
    contact       text,
    fisher        text
);

-- <<COPY_CMD>> -- replaced by 003_import_fishers.sh at runtime

-- Abort if any NHS codes already exist in the person table
DO $$
DECLARE dupe_count int;
BEGIN
    SELECT COUNT(*) INTO dupe_count
    FROM person p
    JOIN fishers_staging f ON TRIM(f.nhs) = p.nhs;

    IF dupe_count > 0 THEN
        RAISE EXCEPTION 'Duplicate NHS codes: % row(s) already exist in person table', dupe_count;
    END IF;
END $$;

INSERT INTO person (nhs, village_id, firstname, lastname, gender, year_of_birth, nrc, contact, fisher)
SELECT
    TRIM(nhs),
    NULLIF(TRIM(village_id),    '')::bigint,
    TRIM(firstname),
    TRIM(lastname),
    NULLIF(TRIM(gender),        ''),
    NULLIF(TRIM(year_of_birth), '')::bigint,
    NULLIF(TRIM(nrc),           ''),
    NULLIF(TRIM(contact),       ''),
    TRIM(fisher)::boolean
FROM fishers_staging;

COMMIT;
