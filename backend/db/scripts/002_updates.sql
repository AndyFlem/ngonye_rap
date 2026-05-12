begin;

DROP VIEW public.v_person;

ALTER TABLE IF EXISTS public.person
    ADD COLUMN fisher boolean;

ALTER TABLE IF EXISTS public.person
    ADD COLUMN year_of_birth bigint;

ALTER TABLE IF EXISTS public.person
    ADD COLUMN village_id bigint;

ALTER TABLE IF EXISTS public.person
    ADD COLUMN nhs character varying(10);

update person set year_of_birth=2021-age
where age is not null;

update person set village_id=h.village_id from 
	households h where person.pah=h.pah;

ALTER TABLE IF EXISTS public.person DROP COLUMN IF EXISTS age;

CREATE OR REPLACE VIEW public.v_person
 AS
 SELECT p.person_id,
    p.pah,
	p.nhs,
    p.household_head,
    p.cosignatory,
	p.fisher,
	p.village_id,
	v.village,
    p.firstname,
    p.middlename,
    p.lastname,
    concat(p.lastname, ', ', concat_ws(' '::text, p.firstname, p.middlename)) AS fullname,
    p.nrc,
    p.contact,
    p.contact2,
    p.gender,
    p.year_of_birth,
    p.relationship,
    p.marital_status,
    p.pregnant_this_year,
    p.residential_status,
    p.education,
    p.primary_occupation,
    p.secondary_occupation,
    p.primary_skill,
    p.secondary_skill,
    p.disabled,
    p.disabilities,
    p.district,
    p.origin
   FROM 
   	person p
	LEFT JOIN villages v on p.village_id=v.village_id;

ALTER TABLE public.v_person
    OWNER TO postgres;

COMMIT;