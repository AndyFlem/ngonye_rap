begin;

ALTER TABLE IF EXISTS public.icas
    ADD COLUMN type character varying(30);

update icas set "type"='Non-affected' from households h where icas.pah=h.pah and h.nonaffected=true;
update icas set "type"='Household' from households h where icas.pah=h.pah and h.nonaffected=false;

commit;