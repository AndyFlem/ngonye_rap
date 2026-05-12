BEGIN;

UPDATE person set cosignatory=false where person_id=937;
UPDATE person set cosignatory=true where person_id=1480;
UPDATE households set cosignatory_id=1480 where pah='PAH685';
DELETE FROM person where person_id=937;

ALTER TABLE IF EXISTS public.person
    ADD COLUMN fisher_village_id bigint;

update person set  fisher_village_id=village_id where fisher=true;

COMMIT;