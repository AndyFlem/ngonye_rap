BEGIN;

-- Make pah nullable so fisher grievances (nhs only) are valid
ALTER TABLE public.grievances
  ALTER COLUMN pah DROP NOT NULL;

-- Add nhs column
ALTER TABLE public.grievances
  ADD COLUMN nhs character varying(10);

-- Enforce: every grievance must belong to either a household or a fisher
ALTER TABLE public.grievances
  ADD CONSTRAINT grievances_entity_check
  CHECK (pah IS NOT NULL OR nhs IS NOT NULL);

-- FK to fishers table
ALTER TABLE public.grievances
  ADD CONSTRAINT grievances_nhs_fkey
  FOREIGN KEY (nhs) REFERENCES public.fishers(nhs);

COMMIT;
