begin;
ALTER TABLE IF EXISTS public.person
    ADD COLUMN created_at date;

ALTER TABLE IF EXISTS public.person
    ADD COLUMN created_user_id bigint;

UPDATE person set nhs = pairs.nhs from
(select nhs,pah from person where household_head=true and nhs is not null) as pairs
where
pairs.pah=person.pah;

UPDATE person set created_at=hs.survey_date::date
FROM
	households_survey hs
where person.pah=hs.pah;

update person set created_at='2022-05-01' where created_at is null;

commit;