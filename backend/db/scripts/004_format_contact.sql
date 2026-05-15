BEGIN;

UPDATE public.person
SET contact = '0' || contact
WHERE contact LIKE '9%';

UPDATE public.person
SET contact2 = '0' || contact2
WHERE contact2 LIKE '9%';

COMMIT;
