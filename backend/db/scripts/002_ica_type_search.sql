begin;

DROP FUNCTION IF EXISTS public.a_households_search;
-- Add p_ica_type parameter to the households search function so households
-- can be filtered by their households.ica_type value.
CREATE OR REPLACE FUNCTION public.a_households_search(
  p_household_head character varying DEFAULT NULL::character varying,
  p_pah character varying DEFAULT NULL::character varying,
  p_vulnerable boolean DEFAULT NULL::boolean,
  p_landholding_only boolean DEFAULT NULL::boolean,
  p_new_ica_required boolean DEFAULT NULL::boolean,
  p_icasigned boolean DEFAULT NULL::boolean,
  p_followup_flag boolean DEFAULT NULL::boolean,
  p_physically_displaced boolean DEFAULT NULL::boolean,
  p_nrc character varying DEFAULT NULL::character varying,
  p_village_id bigint DEFAULT NULL::bigint,
  p_icaoption_primary_structure character varying DEFAULT NULL::character varying,
  p_icaoption_structure_location character varying DEFAULT NULL::character varying,
  p_icaoption_landholding character varying DEFAULT NULL::character varying,
  p_icaoption_dryland character varying DEFAULT NULL::character varying,
  p_icaoption_garden character varying DEFAULT NULL::character varying,
  p_icaoption_transport character varying DEFAULT NULL::character varying,
  p_has_replacement_structures boolean DEFAULT NULL::boolean,
  p_has_replacement_land boolean DEFAULT NULL::boolean,
  p_has_protected boolean DEFAULT NULL::boolean,
  p_survey_complete boolean DEFAULT NULL::boolean,
  p_has_current_grievance boolean DEFAULT NULL::boolean,
  p_has_multiple_icas boolean DEFAULT NULL::boolean,
  p_has_linked_fisher boolean DEFAULT NULL::boolean,
  p_has_notes boolean DEFAULT NULL::boolean,
  p_is_duplicate boolean DEFAULT NULL::boolean,
  p_ica_type character varying DEFAULT NULL::character varying
)
  RETURNS TABLE(pah character varying, household_head_fullname text, date_signed date)
  LANGUAGE plpgsql
AS $function$
BEGIN
  RETURN QUERY
    SELECT
      h.pah,
      concat(p.lastname, ', ', concat_ws(' '::text, p.firstname, p.middlename)),
      h.date_signed
    FROM
      v_households h
      LEFT JOIN v_household_compensation hc ON h.pah = hc.pah
      LEFT JOIN person p ON h.householdhead_id = p.person_id
    WHERE
      (COALESCE(h.vulnerable,false) = p_vulnerable OR p_vulnerable IS NULL) AND
      (COALESCE(h.landholding_only,false) = p_landholding_only OR p_landholding_only IS NULL) AND
      (COALESCE(h.new_ica_required,false) = p_new_ica_required OR p_new_ica_required IS NULL) AND
      ((h.date_signed IS NULL AND p_icasigned = False) OR (h.date_signed IS NOT NULL AND p_icasigned = True) OR p_icasigned IS NULL) AND
      (COALESCE(h.household_followup_flag,false) = p_followup_flag OR p_followup_flag IS NULL) AND
      (COALESCE(h.physically_displaced,false) = p_physically_displaced OR p_physically_displaced IS NULL) AND
      (h.pah = p_pah OR p_pah IS NULL) AND
      (p.nrc ILIKE '%' || p_nrc || '%' OR p_nrc IS NULL) AND
      (h.village_id = p_village_id OR p_village_id IS NULL) AND
      (h.icaoption_primary_structure = p_icaoption_primary_structure OR p_icaoption_primary_structure IS NULL) AND
      (h.icaoption_structure_location = p_icaoption_structure_location OR p_icaoption_structure_location IS NULL) AND
      (h.icaoption_landholding = p_icaoption_landholding OR p_icaoption_landholding IS NULL) AND
      (h.icaoption_dryland = p_icaoption_dryland OR p_icaoption_dryland IS NULL) AND
      (h.icaoption_garden = p_icaoption_garden OR p_icaoption_garden IS NULL) AND
      (h.icaoption_transport = p_icaoption_transport OR p_icaoption_transport IS NULL) AND
      (h.ica_type = p_ica_type OR p_ica_type IS NULL) AND
      ((COALESCE(h.replacement_structures_count, 0) > 0) = p_has_replacement_structures OR p_has_replacement_structures IS NULL) AND
      ((COALESCE(h.replacement_land_area, 0) > 0) = p_has_replacement_land OR p_has_replacement_land IS NULL) AND
      (COALESCE(h.has_protected,false) = p_has_protected OR p_has_protected IS NULL) AND
      (COALESCE(h.survey_complete,false) = p_survey_complete OR p_survey_complete IS NULL) AND
      ((EXISTS (SELECT 1 FROM public.v_grievances g WHERE g.pah = h.pah AND g.is_current = true)) = p_has_current_grievance OR p_has_current_grievance IS NULL) AND
      (((SELECT COUNT(*) FROM public.icas WHERE icas.pah = h.pah) > 1) = p_has_multiple_icas OR p_has_multiple_icas IS NULL) AND
      ((EXISTS (SELECT 1 FROM public.v_person pm WHERE pm.pah = h.pah AND pm.nhs IS NOT NULL)) = p_has_linked_fisher OR p_has_linked_fisher IS NULL) AND
      ((EXISTS (SELECT 1 FROM public.notes n WHERE n.pah = h.pah)) = p_has_notes OR p_has_notes IS NULL) AND
      ((h.duplicate_pah IS NOT NULL) = p_is_duplicate OR p_is_duplicate IS NULL) AND
      (
        (SIMILARITY(p.firstname, p_household_head) > 0.4 OR p_household_head IS NULL) OR
        (SIMILARITY(p.lastname, p_household_head) > 0.4 OR p_household_head IS NULL) OR
        (SIMILARITY(p.middlename, p_household_head) > 0.4 OR p_household_head IS NULL)
      )
    ORDER BY h.pah;
END
$function$;

commit;
