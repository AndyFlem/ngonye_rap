-- Add p_has_linked_household filter to a_fishers_search
-- Returns fishers whose linked person record has pah IS NOT NULL (true) or IS NULL (false)
-- Drop the old 13-param overload to avoid ambiguity on no-arg calls
DROP FUNCTION IF EXISTS public.a_fishers_search(character varying, character varying, character varying, character varying, integer, boolean, boolean, character varying, character varying, boolean, boolean, boolean, boolean);

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
  p_followup_flag boolean DEFAULT NULL::boolean,
  p_ica_signed boolean DEFAULT NULL::boolean,
  p_new_ica_required boolean DEFAULT NULL::boolean,
  p_has_multiple_icas boolean DEFAULT NULL::boolean,
  p_has_linked_household boolean DEFAULT NULL::boolean
)
RETURNS TABLE(nhs character varying)
LANGUAGE plpgsql
AS $function$
BEGIN
  RETURN QUERY
  SELECT f.nhs
  FROM   public.fishers f
  LEFT JOIN public.person p ON f.person_id = p.person_id
  LEFT JOIN public.icas i ON f.nhs = i.nhs AND i.is_current = true
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
    (p_ica_signed IS NULL OR (i.date_signed IS NOT NULL) = p_ica_signed) AND
    (p_new_ica_required IS NULL OR f.new_ica_required = p_new_ica_required) AND
    (p_has_multiple_icas IS NULL OR ((SELECT COUNT(*) FROM public.icas WHERE icas.nhs = f.nhs) > 1) = p_has_multiple_icas) AND
    (p_has_linked_household IS NULL OR (p.pah IS NOT NULL) = p_has_linked_household) AND
    (
      p_name IS NULL OR
      SIMILARITY(p.firstname, p_name) > 0.4 OR
      SIMILARITY(p.lastname,  p_name) > 0.4
    )
  ORDER BY f.nhs;
END
$function$;
