\set ON_ERROR_STOP on

BEGIN;

-- Load accepted 1:1 duplicate pairs from fisher_duplicate_candidates.csv.
-- CSV has 21 columns; col 8 is empty (artefact of psql output format).
CREATE TEMP TABLE dup_staging (
    fisher_person_id    text,
    fisher_nhs          text,
    fisher_firstname    text,
    fisher_lastname     text,
    fisher_village_id   text,
    fisher_nrc          text,
    fisher_contact      text,
    _empty              text,   -- col 8 artefact
    existing_person_id  text,
    existing_pah        text,
    existing_firstname  text,
    existing_lastname   text,
    existing_village_id text,
    existing_nrc        text,
    existing_contact    text,
    firstname_sim       text,
    lastname_sim        text,
    village_match       text,
    nrc_match           text,
    contact_match       text,
    match_score         text
);

-- <<COPY_CMD>>

-- Typed pairs — CSV is strict 1:1 on both sides
CREATE TEMP TABLE pairs AS
SELECT
    fisher_person_id::bigint   AS fisher_pid,
    fisher_nhs,
    existing_person_id::bigint AS existing_pid
FROM dup_staging
WHERE fisher_person_id ~ '^\d+$';

-- 1. Set fisher=true, copy nhs and fisher_village_id from fisher record to existing record
UPDATE person p SET
    fisher            = true,
    nhs               = pf.nhs,
    fisher_village_id = pf.fisher_village_id
FROM pairs pr
JOIN person pf ON pf.person_id = pr.fisher_pid
WHERE p.person_id = pr.existing_pid;

-- 2. contact2: copy fisher contact when it differs from existing contact
UPDATE person p SET
    contact2 = pf.contact
FROM pairs pr
JOIN person pf ON pf.person_id = pr.fisher_pid
WHERE p.person_id = pr.existing_pid
  AND pf.contact IS NOT NULL
  AND pf.contact IS DISTINCT FROM p.contact;

-- 3a. nrc: existing has none, fisher does → use fisher's
UPDATE person p SET
    nrc = pf.nrc
FROM pairs pr
JOIN person pf ON pf.person_id = pr.fisher_pid
WHERE p.person_id = pr.existing_pid
  AND p.nrc IS NULL
  AND pf.nrc IS NOT NULL;

-- 3b. nrc: both have nrc, fisher matches proper format (digits/digits/digits),
--     existing does not → use fisher's
UPDATE person p SET
    nrc = pf.nrc
FROM pairs pr
JOIN person pf ON pf.person_id = pr.fisher_pid
WHERE p.person_id = pr.existing_pid
  AND p.nrc IS NOT NULL
  AND pf.nrc IS NOT NULL
  AND pf.nrc ~ '^\d+/\d+/\d+$'
  AND p.nrc  !~ '^\d+/\d+/\d+$';

-- 4. Update fishers table: point each fisher nhs entry to the surviving person_id
UPDATE fishers f SET
    person_id = pr.existing_pid
FROM pairs pr
WHERE f.nhs = pr.fisher_nhs;

-- 5. Delete the now-redundant fisher person records
DELETE FROM person
WHERE person_id IN (SELECT fisher_pid FROM pairs);

COMMIT;
