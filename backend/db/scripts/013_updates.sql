begin;

-- Make icas polymorphic (same pattern as notes/grievances)
ALTER TABLE public.icas ALTER COLUMN pah DROP NOT NULL;
ALTER TABLE public.icas ADD COLUMN nhs character varying(10);
ALTER TABLE public.icas ADD CONSTRAINT icas_entity_check
  CHECK (pah IS NOT NULL OR nhs IS NOT NULL);
ALTER TABLE public.icas ADD CONSTRAINT icas_nhs_fkey
  FOREIGN KEY (nhs) REFERENCES public.fishers(nhs);

-- Add new_ica_required flag to fishers (analogous to households)
ALTER TABLE public.fishers ADD COLUMN new_ica_required boolean NOT NULL DEFAULT false;

commit;
