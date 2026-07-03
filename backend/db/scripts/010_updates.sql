begin;

CREATE OR REPLACE FUNCTION public.a_replacements_search(
  p_pah character varying DEFAULT NULL::character varying,
  p_replacement_structure_id character varying DEFAULT NULL::character varying,
  p_replacement_option character varying DEFAULT NULL::character varying,
  p_replacement_class character varying DEFAULT NULL::character varying,
  p_icaoption_structure_location character varying DEFAULT NULL::character varying,
  p_protected boolean DEFAULT NULL::boolean,
  p_flag_followup boolean DEFAULT NULL::boolean,
  p_phase character varying DEFAULT NULL::character varying,
  p_silumesii boolean DEFAULT NULL::boolean
)
RETURNS TABLE(replacement_structure_id character varying, pah character varying)
LANGUAGE plpgsql
AS $function$
BEGIN
  RETURN QUERY
  SELECT rs.replacement_structure_id, rs.pah
  FROM   v_replacement_structures rs
  WHERE  (p_pah IS NULL OR rs.pah ILIKE '%' || p_pah || '%')
    AND  (p_replacement_structure_id IS NULL OR rs.replacement_structure_id = p_replacement_structure_id)
    AND  (p_replacement_option IS NULL OR rs.replacement_option = p_replacement_option)
    AND  (p_replacement_class IS NULL OR rs.replacement_class = p_replacement_class)
    AND  (p_icaoption_structure_location IS NULL OR rs.icaoption_structure_location = p_icaoption_structure_location)
    AND  (p_protected IS NULL OR COALESCE(rs.protected,false) = p_protected)
    AND  (p_flag_followup IS NULL OR COALESCE(rs.flag_followup,false) = p_flag_followup)
    AND  (p_phase IS NULL OR rs.phase = p_phase)
    AND  (p_silumesii IS NULL OR COALESCE(rs.silumesii,false) = p_silumesii);
END;
$function$;

commit;
