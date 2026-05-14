begin;


ALTER TABLE IF EXISTS public.fishers
    ADD COLUMN lr_fishfarming boolean;

ALTER TABLE IF EXISTS public.fishers
    ADD COLUMN lr_goatrearing boolean;


CREATE OR REPLACE VIEW public.v_fishers
 AS
 SELECT f.nhs,
    f.person_id,
    concat(ph.lastname, ', ', concat_ws(' '::text, ph.firstname, ph.middlename)) AS fullname,
    f.survey_phase,
    f.social_survey,
    f.catch_survey,
    f.catch_data_survey,
    f.type,
    f.maungwe_active,
    f.maungwe_annual_earnings,
    f.maungwe_traps,
    f.limbelo_active,
    f.limbelo_annual_earnings,
    f.limbelo_traps,
    f.limbelo_annual_buckets,
    f.limbelo_days_fished,
    ((COALESCE(f.limbelo_traps, 0) + COALESCE(f.maungwe_traps, 0)) * 2)::numeric * 12.5 AS site_compensation_calc,
    GREATEST(((COALESCE(f.limbelo_traps, 0) + COALESCE(f.maungwe_traps, 0)) * 2)::numeric * 12.5, 500::numeric) AS site_compensation,
        CASE
            WHEN f.maungwe_active::text = 'Active'::text THEN COALESCE(f.maungwe_traps, 0) * 1500
            ELSE 0
        END AS maungwe_annual_earn,
    COALESCE(f.limbelo_annual_buckets, 0::numeric) AS limbelo_annual_earn,
        CASE
            WHEN f.maungwe_active::text = 'Active'::text THEN COALESCE(f.maungwe_traps, 0) * 1500
            ELSE 0
        END::numeric + COALESCE(f.limbelo_annual_buckets, 0::numeric) * 332::numeric AS transitional_allowance,
    GREATEST(((COALESCE(f.limbelo_traps, 0) + COALESCE(f.maungwe_traps, 0)) * 2)::numeric * 12.5, 500::numeric) +
        CASE
            WHEN f.maungwe_active::text = 'Active'::text THEN COALESCE(f.maungwe_traps, 0) * 1500
            ELSE 0
        END::numeric + COALESCE(f.limbelo_annual_buckets, 0::numeric) * 332::numeric AS total_compensation,
    i.date_signed,
    i.ica_link,
    f.new_ica_required,
    f.followup_flag,
    ph.pah AS linked_pah,
	f.lr_fishfarming,
	f.lr_goatrearing
   FROM fishers f
     JOIN person ph ON f.person_id = ph.person_id
     LEFT JOIN icas i ON f.nhs::text = i.nhs::text AND i.is_current = true;

ALTER TABLE public.v_fishers
    OWNER TO postgres;

commit;