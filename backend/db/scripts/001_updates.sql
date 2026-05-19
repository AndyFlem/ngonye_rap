begin;
ALTER TABLE IF EXISTS public.person
    ADD COLUMN created_at date;

ALTER TABLE IF EXISTS public.person
    ADD COLUMN created_user_id bigint;

UPDATE person set nhs = pairs.nhs from
(select nhs,pah from person where household_head=true and nhs is not null) as pairs
where
pairs.pah=person.pah;
    
commit;