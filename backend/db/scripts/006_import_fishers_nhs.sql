\set ON_ERROR_STOP on

BEGIN;

CREATE TABLE public.fishers (
    nhs                     varchar(10)    NOT NULL PRIMARY KEY,
    person_id               bigint         REFERENCES public.person(person_id),
    survey_phase            smallint,
    social_survey           boolean,
    catch_survey            boolean,
    catch_data_survey       boolean,
    type                    varchar(20),
    maungwe_active          varchar(20),
    maungwe_annual_earnings numeric(12,2),
    limbelo_active          varchar(20),
    limbelo_annual_earnings numeric(12,2),
    limbelo_traps           integer,
    maungwe_traps           integer,
    limbelo_annual_buckets  numeric(10,3),
    limbelo_days_fished     numeric(8,2)
);

CREATE TEMP TABLE fishers_staging (
    nhs                     text,
    person_id               text,
    survey_phase            text,
    social_survey           text,
    catch_survey            text,
    catch_data_survey       text,
    type                    text,
    maungwe_active          text,
    maungwe_annual_earnings text,
    limbelo_active          text,
    limbelo_annual_earnings text,
    limbelo_traps           text,
    maungwe_traps           text,
    limbelo_annual_buckets  text,
    limbelo_days_fished     text
);

-- <<COPY_CMD>>

INSERT INTO public.fishers (
    nhs, person_id, survey_phase,
    social_survey, catch_survey, catch_data_survey,
    type,
    maungwe_active, maungwe_annual_earnings,
    limbelo_active, limbelo_annual_earnings,
    limbelo_traps, maungwe_traps,
    limbelo_annual_buckets, limbelo_days_fished
)
SELECT
    TRIM(nhs),
    NULLIF(TRIM(person_id),         '')::bigint,
    NULLIF(TRIM(survey_phase),      '')::smallint,

    CASE TRIM(social_survey)     WHEN 'Yes' THEN true WHEN 'No' THEN false END,
    CASE TRIM(catch_survey)      WHEN 'Yes' THEN true WHEN 'No' THEN false END,
    CASE TRIM(catch_data_survey) WHEN 'Yes' THEN true WHEN 'No' THEN false END,

    NULLIF(TRIM(type),              ''),

    NULLIF(TRIM(maungwe_active),  ''),
    NULLIF(TRIM(REPLACE(maungwe_annual_earnings, ',', '')), '')::numeric,

    NULLIF(TRIM(limbelo_active),  ''),
    NULLIF(TRIM(REPLACE(limbelo_annual_earnings, ',', '')), '')::numeric,

    NULLIF(TRIM(limbelo_traps),     '')::integer,
    NULLIF(TRIM(maungwe_traps),     '')::integer,
    NULLIF(TRIM(limbelo_annual_buckets), '')::numeric,
    NULLIF(TRIM(limbelo_days_fished),    '')::numeric

FROM fishers_staging;

COMMIT;
