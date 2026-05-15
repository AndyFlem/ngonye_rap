begin;

ALTER TABLE IF EXISTS public.households_survey
    ADD COLUMN survey_link text;

commit;