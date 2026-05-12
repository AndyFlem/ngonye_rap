BEGIN;

-- Make pah nullable so fisher notes (nhs only) are valid
ALTER TABLE public.notes
  ALTER COLUMN pah DROP NOT NULL;

-- Add nhs column
ALTER TABLE public.notes
  ADD COLUMN nhs character varying(10);

-- Enforce: every note must belong to either a household or a fisher
ALTER TABLE public.notes
  ADD CONSTRAINT notes_entity_check
  CHECK (pah IS NOT NULL OR nhs IS NOT NULL);

-- FK to fishers table
ALTER TABLE public.notes
  ADD CONSTRAINT notes_nhs_fkey
  FOREIGN KEY (nhs) REFERENCES public.fishers(nhs);

-- Recreate v_notes to expose nhs column (must drop first — adding mid-column breaks CREATE OR REPLACE)
DROP VIEW IF EXISTS public.v_notes;
CREATE VIEW public.v_notes AS
SELECT
  n.note_id,
  n.user_id,
  n.pah,
  n.nhs,
  n.note,
  n.created_at,
  (u.first_name || ' ' || u.last_name) AS created_by
FROM public.notes n
LEFT JOIN public."user" u ON u.user_id = n.user_id;

ALTER VIEW public.v_notes OWNER TO postgres;

COMMIT;
