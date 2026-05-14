-- Add p_has_notes filter to a_households_search and a_fishers_search

CREATE OR REPLACE FUNCTION public.a_households_search(
  p_household_head character varying DEFAULT NULL::character varying,
  p_pah character varying DEFAULT NULL::character varying,
  p_vulnerable boolean DEFAULT NULL::boolean,
  p_nonaffected boolean DEFAULT NULL::boolean,
  p_landholding_only boolean DEFAULT NULL::boolean,
  p_silumesii boolean DEFAULT NULL::boolean,
  p_new_ica_required boolean DEFAULT NULL::boolean,
  p_no_ica_required boolean DEFAULT NULL::boolean,
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
  p_has_notes boolean DEFAULT NULL::boolean
) RETURNS TABLE(pah character varying, household_head_fullname text, date_signed date)
  LANGUAGE plpgsql
  AS $$
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
      (h.vulnerable = p_vulnerable OR p_vulnerable IS NULL) AND
      (h.nonaffected = p_nonaffected OR p_nonaffected IS NULL) AND
      (h.landholding_only = p_landholding_only OR p_landholding_only IS NULL) AND
      (h.silumesii = p_silumesii OR p_silumesii IS NULL) AND
      (h.new_ica_required = p_new_ica_required OR p_new_ica_required IS NULL) AND
      (h.no_ica_required = p_no_ica_required OR p_no_ica_required IS NULL) AND
      ((h.date_signed IS NULL AND p_icasigned = False) OR (h.date_signed IS NOT NULL AND p_icasigned = True) OR p_icasigned IS NULL) AND
      (h.household_followup_flag = p_followup_flag OR p_followup_flag IS NULL) AND
      (h.physically_displaced = p_physically_displaced OR p_physically_displaced IS NULL) AND
      (h.pah = p_pah OR p_pah IS NULL) AND
      (p.nrc ILIKE '%' || p_nrc || '%' OR p_nrc IS NULL) AND
      (h.village_id = p_village_id OR p_village_id IS NULL) AND
      (h.icaoption_primary_structure = p_icaoption_primary_structure OR p_icaoption_primary_structure IS NULL) AND
      (h.icaoption_structure_location = p_icaoption_structure_location OR p_icaoption_structure_location IS NULL) AND
      (h.icaoption_landholding = p_icaoption_landholding OR p_icaoption_landholding IS NULL) AND
      (h.icaoption_dryland = p_icaoption_dryland OR p_icaoption_dryland IS NULL) AND
      (h.icaoption_garden = p_icaoption_garden OR p_icaoption_garden IS NULL) AND
      (h.icaoption_transport = p_icaoption_transport OR p_icaoption_transport IS NULL) AND
      ((COALESCE(h.replacement_structures_count, 0) > 0) = p_has_replacement_structures OR p_has_replacement_structures IS NULL) AND
      ((COALESCE(h.replacement_land_area, 0) > 0) = p_has_replacement_land OR p_has_replacement_land IS NULL) AND
      (h.has_protected = p_has_protected OR p_has_protected IS NULL) AND
      (h.survey_complete = p_survey_complete OR p_survey_complete IS NULL) AND
      ((EXISTS (SELECT 1 FROM public.grievances g WHERE g.pah = h.pah AND g.is_current = true)) = p_has_current_grievance OR p_has_current_grievance IS NULL) AND
      (((SELECT COUNT(*) FROM public.icas WHERE icas.pah = h.pah) > 1) = p_has_multiple_icas OR p_has_multiple_icas IS NULL) AND
      ((EXISTS (SELECT 1 FROM public.person pm WHERE pm.pah = h.pah AND pm.nhs IS NOT NULL)) = p_has_linked_fisher OR p_has_linked_fisher IS NULL) AND
      ((EXISTS (SELECT 1 FROM public.notes n WHERE n.pah = h.pah)) = p_has_notes OR p_has_notes IS NULL) AND
      (
        (SIMILARITY(p.firstname, p_household_head) > 0.4 OR p_household_head IS NULL) OR
        (SIMILARITY(p.lastname, p_household_head) > 0.4 OR p_household_head IS NULL) OR
        (SIMILARITY(p.middlename, p_household_head) > 0.4 OR p_household_head IS NULL)
      )
    ORDER BY h.pah;
END
$$;


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
  p_has_linked_household boolean DEFAULT NULL::boolean,
  p_has_notes boolean DEFAULT NULL::boolean
) RETURNS TABLE(nhs character varying)
  LANGUAGE plpgsql
  AS $$
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
    (p_has_notes IS NULL OR (EXISTS (SELECT 1 FROM public.notes n WHERE n.nhs = f.nhs)) = p_has_notes) AND
    (
      p_name IS NULL OR
      SIMILARITY(p.firstname, p_name) > 0.4 OR
      SIMILARITY(p.lastname,  p_name) > 0.4
    )
  ORDER BY f.nhs;
END
$$;
