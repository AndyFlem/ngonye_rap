BEGIN;

-- ── 1. Add new columns (contact and nrc already exist) ──────────────────────
--
--  Column    CSV name   Type        Max observed length
--  ───────── ────────── ─────────── ───────────────────
--  contact2  contact2   VARCHAR     10
--  district  district   VARCHAR     12 ("Itezhi-tezhi")
--  origin    origin     VARCHAR     16 ("Western Province")

ALTER TABLE person
    ADD COLUMN IF NOT EXISTS contact2  VARCHAR(100),
    ADD COLUMN IF NOT EXISTS district  VARCHAR(100),
    ADD COLUMN IF NOT EXISTS origin    VARCHAR(100);

-- ── 2. Load CSV into staging table ──────────────────────────────────────────
CREATE TEMP TABLE contact_staging (
    person_id  BIGINT,
    contact    VARCHAR(100),
    contact2   VARCHAR(100),
    nrc        VARCHAR(100),
    district   VARCHAR(100),
    origin     VARCHAR(100)
);

\copy contact_staging (person_id, contact, contact2, nrc, district, origin) FROM '/home/andy/ngonye_rap/backend/incoming_data/contact.csv' WITH (FORMAT csv, HEADER true, NULL '');

-- ── 3. Validate: every CSV row must join to an existing person ───────────────
DO $$
DECLARE
    missing_count INT;
    missing_ids   TEXT;
BEGIN
    SELECT COUNT(*), string_agg(person_id::TEXT, ', ' ORDER BY person_id)
    INTO missing_count, missing_ids
    FROM contact_staging
    WHERE person_id NOT IN (SELECT person_id FROM person);

    IF missing_count > 0 THEN
        RAISE EXCEPTION
            'Import aborted: % CSV row(s) have no matching person record. Missing person_id(s): %',
            missing_count, missing_ids;
    END IF;

    RAISE NOTICE 'Validation passed: all % CSV rows join to an existing person record.',
        (SELECT COUNT(*) FROM contact_staging);
END $$;

-- ── 4. Report duplicate PersonIds in the CSV ────────────────────────────────
--
--  Known duplicates as of import (May 2026):
--    105  – near-duplicate (trailing space in district); TRIM makes them identical
--    467  – conflicting data (contact present in one row, absent in the other)
--
--  After trimming whitespace, exact duplicates are collapsed via DISTINCT.
--  For remaining duplicates the last occurrence in the file is used (ctid DESC).

DO $$
DECLARE
    r RECORD;
BEGIN
    FOR r IN
        SELECT person_id, COUNT(*) AS n
        FROM contact_staging
        GROUP BY person_id
        HAVING COUNT(*) > 1
        ORDER BY person_id
    LOOP
        RAISE NOTICE 'Duplicate PersonId % appears % times in CSV; last occurrence will be used.',
            r.person_id, r.n;
    END LOOP;
END $$;

-- ── 5. Update person rows from CSV ──────────────────────────────────────────
DO $$
DECLARE
    updated_count INT;
BEGIN
    WITH deduped AS (
        SELECT DISTINCT ON (person_id)
            person_id,
            NULLIF(TRIM(contact),  '') AS contact,
            NULLIF(TRIM(contact2), '') AS contact2,
            NULLIF(TRIM(nrc),      '') AS nrc,
            NULLIF(TRIM(district), '') AS district,
            NULLIF(TRIM(origin),   '') AS origin
        FROM contact_staging
        ORDER BY person_id, ctid DESC
    )
    UPDATE person p
    SET
        contact   = d.contact,
        contact2  = d.contact2,
        nrc       = d.nrc,
        district  = d.district,
        origin    = d.origin
    FROM deduped d
    WHERE p.person_id = d.person_id;

    GET DIAGNOSTICS updated_count = ROW_COUNT;
    RAISE NOTICE 'Updated % person row(s).', updated_count;
END $$;

COMMIT;
