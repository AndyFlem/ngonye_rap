-- Identifies candidate duplicate pairs between fisher records (fisher=true)
-- and existing non-fisher person records.
--
-- Scoring weights:
--   firstname similarity  : 0.20
--   lastname  similarity  : 0.20
--   village_id exact match: 0.10
--   NRC exact match       : 0.35  (near-definitive)
--   contact exact match   : 0.15
--
-- A pair is included if match_score >= 0.40, OR nrc_match=1, OR contact_match=1.
-- Results ordered by match_score DESC for human review.

WITH fishers AS (
    SELECT
        person_id,
        nhs,
        TRIM(COALESCE(firstname, '')) AS firstname,
        TRIM(COALESCE(lastname,  '')) AS lastname,
        village_id,
        NULLIF(TRIM(COALESCE(nrc,     '')), '') AS nrc,
        NULLIF(TRIM(COALESCE(contact, '')), '') AS contact
    FROM person
    WHERE fisher = true
),
non_fishers AS (
    SELECT
        person_id,
        pah,
        TRIM(COALESCE(firstname, '')) AS firstname,
        TRIM(COALESCE(lastname,  '')) AS lastname,
        village_id,
        NULLIF(TRIM(COALESCE(nrc,     '')), '') AS nrc,
        NULLIF(TRIM(COALESCE(contact, '')), '') AS contact
    FROM person
    WHERE fisher IS NOT TRUE
      AND firstname IS NOT NULL
),
scored AS (
    SELECT
        f.person_id                                    AS fisher_person_id,
        f.nhs                                          AS fisher_nhs,
        f.firstname                                    AS fisher_firstname,
        f.lastname                                     AS fisher_lastname,
        f.village_id                                   AS fisher_village_id,
        f.nrc                                          AS fisher_nrc,
        f.contact                                      AS fisher_contact,

        nf.person_id                                   AS existing_person_id,
        nf.pah                                         AS existing_pah,
        nf.firstname                                   AS existing_firstname,
        nf.lastname                                    AS existing_lastname,
        nf.village_id                                  AS existing_village_id,
        nf.nrc                                         AS existing_nrc,
        nf.contact                                     AS existing_contact,

        ROUND(similarity(f.firstname, nf.firstname)::numeric, 3) AS firstname_sim,
        ROUND(similarity(f.lastname,  nf.lastname )::numeric, 3) AS lastname_sim,

        CASE WHEN f.village_id = nf.village_id                                         THEN 1 ELSE 0 END AS village_match,
        CASE WHEN f.nrc IS NOT NULL AND nf.nrc IS NOT NULL AND f.nrc = nf.nrc          THEN 1 ELSE 0 END AS nrc_match,
        CASE WHEN f.contact IS NOT NULL AND nf.contact IS NOT NULL AND f.contact = nf.contact THEN 1 ELSE 0 END AS contact_match,

        ROUND((
            similarity(f.firstname, nf.firstname) * 0.20 +
            similarity(f.lastname,  nf.lastname ) * 0.20 +
            CASE WHEN f.village_id = nf.village_id                                               THEN 0.10 ELSE 0 END +
            CASE WHEN f.nrc IS NOT NULL AND nf.nrc IS NOT NULL AND f.nrc = nf.nrc               THEN 0.35 ELSE 0 END +
            CASE WHEN f.contact IS NOT NULL AND nf.contact IS NOT NULL AND f.contact = nf.contact THEN 0.15 ELSE 0 END
        )::numeric, 3) AS match_score

    FROM fishers f
    CROSS JOIN non_fishers nf
)
SELECT *
FROM scored
WHERE match_score >= 0.40
   OR nrc_match     = 1
   OR contact_match = 1
ORDER BY match_score DESC, fisher_person_id, existing_person_id;
