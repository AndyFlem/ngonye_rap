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
  p_icaoption_transport character varying DEFAULT NULL::character varying
)
RETURNS TABLE(pah character varying, household_head_fullname text, date_signed date)
LANGUAGE plpgsql
AS $function$
BEGIN
   RETURN QUERY
	SELECT
		h.pah,
		h.household_head_fullname,
		h.date_signed
	FROM
		v_households h
		LEFT JOIN v_household_compensation hc ON h.pah=hc.pah
	WHERE
		(h.vulnerable = p_vulnerable or p_vulnerable IS NULL) AND
		(h.nonaffected = p_nonaffected or p_nonaffected IS NULL) AND
		(h.landholding_only = p_landholding_only or p_landholding_only IS NULL) AND
		(h.silumesii = p_silumesii or p_silumesii IS NULL) AND
		(h.new_ica_required = p_new_ica_required or p_new_ica_required IS NULL) AND
		(h.no_ica_required = p_no_ica_required or p_no_ica_required IS NULL) AND
		((h.date_signed IS NULL AND p_icasigned = False) OR (h.date_signed IS NOT NULL AND p_icasigned = True) or p_icasigned IS NULL) AND
		(h.household_followup_flag = p_followup_flag or p_followup_flag IS NULL) AND
		(h.physically_displaced = p_physically_displaced or p_physically_displaced IS NULL) AND
		(h.pah=p_pah OR p_pah IS NULL) AND
		(h.nrc ILIKE '%' || p_nrc || '%' OR p_nrc IS NULL) AND
		(h.village_id = p_village_id OR p_village_id IS NULL) AND
		(h.icaoption_primary_structure = p_icaoption_primary_structure OR p_icaoption_primary_structure IS NULL) AND
		(h.icaoption_structure_location = p_icaoption_structure_location OR p_icaoption_structure_location IS NULL) AND
		(h.icaoption_landholding = p_icaoption_landholding OR p_icaoption_landholding IS NULL) AND
		(h.icaoption_dryland = p_icaoption_dryland OR p_icaoption_dryland IS NULL) AND
		(h.icaoption_garden = p_icaoption_garden OR p_icaoption_garden IS NULL) AND
		(h.icaoption_transport = p_icaoption_transport OR p_icaoption_transport IS NULL) AND
		(
			(SIMILARITY(h.firstname,p_household_head) > 0.4 OR p_household_head IS NULL) OR
			(SIMILARITY(h.lastname,p_household_head) > 0.4 OR p_household_head IS NULL) OR
			(SIMILARITY(h.middlename,p_household_head) > 0.4 OR p_household_head IS NULL)
		);
END
$function$
