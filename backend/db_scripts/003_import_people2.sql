BEGIN;

-- ── 1. Add columns if not already present (guards against running out of order)
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
--
--  Age is staged as NUMERIC(4,1) because three rows carry decimal values
--  (e.g. 2.7, 2.4, 1.6 — young children recorded in fractional years).
--  It is rounded to SMALLINT on insert.
--
--  The file is latin-1 encoded (contains ñ in "Iñutu"); ENCODING 'LATIN1'
--  is specified in \copy so PostgreSQL converts to the database's UTF-8.
--
--  Name is split on spaces into firstname / middlename / lastname:
--    1 word  → firstname only          e.g. "Kwaleele"
--    2 words → firstname + lastname    e.g. "Clare Mwenda"
--    3 words → all three parts         e.g. "Tracey Silumesii Musiyalike"
--
--  Column              CSV name               Type        Max observed length
--  ─────────────────── ────────────────────── ─────────── ───────────────────
--  pah                 PAH                    VARCHAR     6
--  name                Name                   VARCHAR     28 ("Tracey Silumesii Musiyalike")
--  gender              Gender                 VARCHAR     6  ("Female")
--  pregnant_this_year  PregnantThisYear       BOOLEAN
--  age                 Age                    NUMERIC     range 0–100, 2 NULLs
--  relationship        Relationship           VARCHAR     22 ("Grandson/Granddaughter")
--  marital_status      MaritalStatus          VARCHAR     10 ("Cohabitant")
--  residential_status  ResidentialStatus      VARCHAR     29
--  education           Education              VARCHAR     37
--  primary_occupation  PrimaryOccupation      VARCHAR     29
--  secondary_occupation SecondaryOccupation   VARCHAR     35
--  primary_skill       PrimarySkill           VARCHAR     25
--  secondary_skill     SecondarySkill         VARCHAR     23
--  disabled            Disabled               BOOLEAN
--  disabilities        Disabilities           VARCHAR     60 (sparse)

CREATE TEMP TABLE people_insert_staging (
    pah                   VARCHAR(9),
    name                  VARCHAR(100),
    gender                VARCHAR(10),
    pregnant_this_year    BOOLEAN,
    age                   NUMERIC(4,1),
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

\copy people_insert_staging (pah, name, gender, pregnant_this_year, age, relationship, marital_status, residential_status, education, primary_occupation, secondary_occupation, primary_skill, secondary_skill, disabled, disabilities) FROM '/home/andy/ngonye_rap/backend/incoming_data/people_insert.csv' WITH (FORMAT csv, HEADER true, NULL '', ENCODING 'LATIN1');

-- ── 3. Report staging stats ──────────────────────────────────────────────────
DO $$
DECLARE
    total_rows INT;
    dupe_rows  INT;
BEGIN
    SELECT COUNT(*) INTO total_rows FROM people_insert_staging;

    SELECT total_rows - COUNT(*)
    INTO dupe_rows
    FROM (
        SELECT DISTINCT pah, name, gender, pregnant_this_year, age, relationship,
               marital_status, residential_status, education, primary_occupation,
               secondary_occupation, primary_skill, secondary_skill,
               disabled, disabilities
        FROM people_insert_staging
    ) deduped;

    RAISE NOTICE 'Staging loaded: % rows (% exact duplicate(s) will be skipped).', total_rows, dupe_rows;
END $$;

-- ── 4. Insert distinct rows into person ─────────────────────────────────────
--
--  Exact duplicate rows are collapsed via DISTINCT.
--  Decimal ages are rounded to the nearest integer (SMALLINT).
--  'None' in optional text fields is normalised to NULL.
--  Name is split by spaces using a LATERAL subquery:
--    parts[1] → firstname, parts[2] → middlename (3-word only), parts[last] → lastname.

DO $$
DECLARE
    inserted_count INT;
BEGIN
    INSERT INTO person (
        firstname, middlename, lastname,
        pah, gender, pregnant_this_year, age,
        relationship, marital_status, residential_status, education,
        primary_occupation, secondary_occupation, primary_skill, secondary_skill,
        disabled, disabilities
    )
    SELECT DISTINCT
        parts[1],
        CASE WHEN cardinality(parts) = 3 THEN parts[2] END,
        CASE WHEN cardinality(parts) >= 2 THEN parts[cardinality(parts)] END,
        pah,
        gender,
        pregnant_this_year,
        ROUND(age)::SMALLINT,
        relationship,
        marital_status,
        residential_status,
        education,
        NULLIF(primary_occupation,   'None'),
        NULLIF(secondary_occupation, 'None'),
        NULLIF(primary_skill,        'None'),
        NULLIF(secondary_skill,      'None'),
        disabled,
        disabilities
    FROM people_insert_staging,
         LATERAL (SELECT string_to_array(trim(name), ' ') AS parts) n;

    GET DIAGNOSTICS inserted_count = ROW_COUNT;
    RAISE NOTICE 'Inserted % new person row(s).', inserted_count;
END $$;

COMMIT;
