
drop function a_households_search;

CREATE OR REPLACE FUNCTION public.a_households_search(
	p_household_head character varying DEFAULT NULL::character varying,
	p_pah character varying DEFAULT NULL::character varying,
	p_vulnerable boolean DEFAULT NULL::boolean,
	p_nonaffected  boolean DEFAULT NULL::boolean,
	p_landholding_only boolean DEFAULT NULL::boolean,
	p_silumesii boolean DEFAULT NULL::boolean,
	p_new_ica_required boolean DEFAULT NULL::boolean,
	p_no_ica_required boolean DEFAULT NULL::boolean,
	p_icasigned boolean DEFAULT NULL::boolean,
	p_followup_flag boolean DEFAULT NULL::boolean,
	p_physically_displaced boolean DEFAULT NULL::boolean
	)
    RETURNS TABLE(pah character varying(9), household_head_fullname text, date_signed date) 
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
    ROWS 1000

AS $BODY$
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
		(
			(SIMILARITY(h.firstname,p_household_head) > 0.4 OR p_household_head IS NULL) OR
			(SIMILARITY(h.lastname,p_household_head) > 0.4 OR p_household_head IS NULL) OR
			(SIMILARITY(h.middlename,p_household_head) > 0.4 OR p_household_head IS NULL)
		);
END
$BODY$;

ALTER FUNCTION public.a_households_search
    OWNER TO postgres;