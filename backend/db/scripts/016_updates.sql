begin;

-- Add followup_flag to fishers table
ALTER TABLE public.fishers ADD COLUMN IF NOT EXISTS followup_flag boolean NOT NULL DEFAULT false;

-- Recreate v_fishers to include followup_flag
CREATE OR REPLACE VIEW public.v_fishers AS
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
     f.followup_flag
    FROM fishers f
      JOIN person ph ON f.person_id = ph.person_id
      LEFT JOIN icas i ON f.nhs::text = i.nhs::text AND i.is_current = true;

-- Drop old 9-param overload before replacing with new 10-param signature
DROP FUNCTION IF EXISTS public.a_fishers_search(varchar,varchar,varchar,varchar,integer,boolean,boolean,varchar,varchar);

-- Update a_fishers_search to support p_followup_flag
CREATE OR REPLACE FUNCTION public.a_fishers_search(
  p_name character varying DEFAULT NULL::character varying,
  p_nhs character varying DEFAULT NULL::character varying,
  p_nrc character varying DEFAULT NULL::character varying,
  p_type character varying DEFAULT NULL::character varying,
  p_survey_phase integer DEFAULT NULL::integer,
  p_social_survey boolean DEFAULT NULL::boolean,
  p_catch_survey boolean DEFAULT NULL::boolean,
  p_maungwe_active character varying DEFAULT NULL::character varying,
  p_limbelo_active character varying DEFAULT NULL::character varying,
  p_followup_flag boolean DEFAULT NULL::boolean
)
RETURNS TABLE(nhs character varying)
LANGUAGE plpgsql
AS $function$
BEGIN
  RETURN QUERY
  SELECT f.nhs
  FROM   public.fishers f
  LEFT JOIN public.person p ON f.person_id = p.person_id
  WHERE
    (p_nhs IS NULL OR f.nhs ILIKE '%' || p_nhs || '%') AND
    (p_nrc IS NULL OR p.nrc ILIKE '%' || p_nrc || '%') AND
    (p_type IS NULL OR f.type = p_type) AND
    (p_survey_phase IS NULL OR f.survey_phase = p_survey_phase) AND
    (p_social_survey IS NULL OR f.social_survey = p_social_survey) AND
    (p_catch_survey IS NULL OR f.catch_survey = p_catch_survey) AND
    (p_maungwe_active IS NULL OR f.maungwe_active = p_maungwe_active) AND
    (p_limbelo_active IS NULL OR f.limbelo_active = p_limbelo_active) AND
    (p_followup_flag IS NULL OR f.followup_flag = p_followup_flag) AND
    (
      p_name IS NULL OR
      SIMILARITY(p.firstname, p_name) > 0.4 OR
      SIMILARITY(p.lastname,  p_name) > 0.4
    )
  ORDER BY f.nhs;
END
$function$;

commit;
