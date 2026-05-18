begin;
ALTER TABLE IF EXISTS public.person
    ADD COLUMN photo_file text;
commit;