CREATE TABLE public.icas (
    ica_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    pah character varying(9) NOT NULL REFERENCES public.households(pah),
    ica_link character varying(500),
    date_signed date,
    is_current boolean NOT NULL DEFAULT true
);

-- Migrate existing data: one row per household that already has ICA data
INSERT INTO public.icas (pah, ica_link, date_signed, is_current)
SELECT pah, ica_link, date_signed, true
FROM public.households
WHERE ica_link IS NOT NULL OR date_signed IS NOT NULL;
