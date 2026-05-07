BEGIN;

-- ── 1. Add new columns (idempotent) ─────────────────────────────────────────
--
--  Column              CSV name               Type      Max observed length
--  ─────────────────── ────────────────────── ───────── ───────────────────
--  gender              Gender                 VARCHAR   6  ("Female")
--  pregnant_this_year  PregnantThisYear       BOOLEAN
--  age                 Age                    SMALLINT  range 19–83, 1 NULL
--  relationship        Relationship           VARCHAR   14 ("Household Head")
--  marital_status      MaritalStatus          VARCHAR   8  ("Divorced")
--  residential_status  ResidentialStatus      VARCHAR   35
--  education           Education              VARCHAR   37
--  primary_occupation  PrimaryOccupation      VARCHAR   35
--  secondary_occupation SecondaryOccupation   VARCHAR   35
--  primary_skill       PrimarySkill           VARCHAR   34
--  secondary_skill     SecondarySkill         VARCHAR   22
--  disabled            Disabled               BOOLEAN
--  disabilities        Disabilities           VARCHAR   38 (sparse)

ALTER TABLE person
    ADD COLUMN IF NOT EXISTS gender               VARCHAR(10),
    ADD COLUMN IF NOT EXISTS pregnant_this_year   BOOLEAN,
    ADD COLUMN IF NOT EXISTS age                  SMALLINT,
    ADD COLUMN IF NOT EXISTS relationship         VARCHAR(50),
    ADD COLUMN IF NOT EXISTS marital_status       VARCHAR(50),
    ADD COLUMN IF NOT EXISTS residential_status   VARCHAR(100),
    ADD COLUMN IF NOT EXISTS education            VARCHAR(100),
    ADD COLUMN IF NOT EXISTS primary_occupation   VARCHAR(100),
    ADD COLUMN IF NOT EXISTS secondary_occupation VARCHAR(100),
    ADD COLUMN IF NOT EXISTS primary_skill        VARCHAR(100),
    ADD COLUMN IF NOT EXISTS secondary_skill      VARCHAR(100),
    ADD COLUMN IF NOT EXISTS disabled             BOOLEAN,
    ADD COLUMN IF NOT EXISTS disabilities         VARCHAR(255);

-- ── 2. Load CSV into staging table ──────────────────────────────────────────
CREATE TEMP TABLE people_staging (
    person_id             BIGINT,
    pah                   VARCHAR(9),
    gender                VARCHAR(10),
    pregnant_this_year    BOOLEAN,
    age                   SMALLINT,
    relationship          VARCHAR(50),
    marital_status        VARCHAR(50),
    residential_status    VARCHAR(100),
    education             VARCHAR(100),
    primary_occupation    VARCHAR(100),
    secondary_occupation  VARCHAR(100),
    primary_skill         VARCHAR(100),
    secondary_skill       VARCHAR(100),
    disabled              BOOLEAN,
    disabilities          VARCHAR(255)
);

\copy people_staging (person_id, pah, gender, pregnant_this_year, age, relationship, marital_status, residential_status, education, primary_occupation, secondary_occupation, primary_skill, secondary_skill, disabled, disabilities) FROM '/home/andy/ngonye_rap/backend/incoming_data/people.csv' WITH (FORMAT csv, HEADER true, NULL '');

-- ── 3. Validate: every CSV row must join to an existing person ───────────────
DO $$
DECLARE
    missing_count INT;
    missing_ids   TEXT;
BEGIN
    SELECT COUNT(*), string_agg(person_id::TEXT, ', ' ORDER BY person_id)
    INTO missing_count, missing_ids
    FROM people_staging
    WHERE person_id NOT IN (SELECT person_id FROM person);

    IF missing_count > 0 THEN
        RAISE EXCEPTION
            'Import aborted: % CSV row(s) have no matching person record. Missing person_id(s): %',
            missing_count, missing_ids;
    END IF;

    RAISE NOTICE 'Validation passed: all % CSV rows join to an existing person record.',
        (SELECT COUNT(*) FROM people_staging);
END $$;

-- ── 4. Report duplicate PersonIDs in the CSV ────────────────────────────────
--
--  Known duplicates as of import (May 2026):
--    106  – exact duplicate row
--    436  – near-duplicate (PrimarySkill typo: missing closing paren)
--    892  – conflicting data (Age 40 vs 41, different occupation/residency)
--    467  – conflicting data (different PAH and SecondaryOccupation)
--
--  The last occurrence in the file is used for each duplicate.

DO $$
DECLARE
    r RECORD;
BEGIN
    FOR r IN
        SELECT person_id, COUNT(*) AS n
        FROM people_staging
        GROUP BY person_id
        HAVING COUNT(*) > 1
        ORDER BY person_id
    LOOP
        RAISE NOTICE 'Duplicate PersonID % appears % times in CSV; last occurrence will be used.',
            r.person_id, r.n;
    END LOOP;
END $$;

-- ── 5. Update person rows from CSV ──────────────────────────────────────────
--
--  Duplicate PersonIDs are resolved by taking the last row as it appears in
--  the file (highest ctid in the temp table).
--
--  'None' in optional text fields is normalised to NULL.

DO $$
DECLARE
    updated_count INT;
BEGIN
    WITH deduped AS (
        SELECT DISTINCT ON (person_id) *
        FROM people_staging
        ORDER BY person_id, ctid DESC
    )
    UPDATE person p
    SET
        pah                  = d.pah,
        gender               = d.gender,
        pregnant_this_year   = d.pregnant_this_year,
        age                  = d.age,
        relationship         = d.relationship,
        marital_status       = d.marital_status,
        residential_status   = d.residential_status,
        education            = d.education,
        primary_occupation   = NULLIF(d.primary_occupation,  'None'),
        secondary_occupation = NULLIF(d.secondary_occupation, 'None'),
        primary_skill        = NULLIF(d.primary_skill,        'None'),
        secondary_skill      = NULLIF(d.secondary_skill,      'None'),
        disabled             = d.disabled,
        disabilities         = d.disabilities
    FROM deduped d
    WHERE p.person_id = d.person_id;

    GET DIAGNOSTICS updated_count = ROW_COUNT;
    RAISE NOTICE 'Updated % person row(s).', updated_count;
END $$;

COMMIT;
