BEGIN;

UPDATE public.person
SET nrc = substring(nrc, 1, 6) || '/' || substring(nrc, 7, 2) || '/' || substring(nrc, 9, 1)
WHERE nrc ~ '^\d{9}$';

COMMIT;
