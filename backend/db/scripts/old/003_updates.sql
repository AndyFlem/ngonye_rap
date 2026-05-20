begin;
ALTER TABLE IF EXISTS public.grievances
    ADD COLUMN date_received date;
commit;