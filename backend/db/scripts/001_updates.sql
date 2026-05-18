begin;
ALTER TABLE IF EXISTS public.person
    ADD COLUMN deceased_date date;


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
    p.origin,
    p.photo_file,
	p.deceased_date
   FROM person p
     LEFT JOIN villages v ON p.village_id = v.village_id;

ALTER TABLE public.v_person
    OWNER TO postgres;


commit;