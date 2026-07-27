begin;

DROP FUNCTION IF EXISTS public.a_structures_search;
-- Search function backing the Structures search page. Mirrors
-- a_replacements_search: every parameter defaults to NULL meaning "don't
-- filter on this", and only the key columns are returned - the controller
-- re-hydrates the full rows from v_structures.
CREATE OR REPLACE FUNCTION public.a_structures_search(
  p_structure_id character varying DEFAULT NULL::character varying,
  p_pah character varying DEFAULT NULL::character varying,
  p_structure_class character varying DEFAULT NULL::character varying,
  p_structure_type character varying DEFAULT NULL::character varying,
  p_land_zone character varying DEFAULT NULL::character varying,
  p_protected boolean DEFAULT NULL::boolean,
  p_followup_flag boolean DEFAULT NULL::boolean,
  p_has_replacement boolean DEFAULT NULL::boolean)
  RETURNS TABLE(structure_id character varying, pah character varying)
    LANGUAGE plpgsql
    AS $$
BEGIN
  RETURN QUERY
  SELECT s.structure_id, s.pah
  FROM   v_structures s
  WHERE  (p_structure_id IS NULL OR s.structure_id = p_structure_id)
    AND  (p_pah IS NULL OR s.pah ILIKE '%' || p_pah || '%')
    AND  (p_structure_class IS NULL OR s.structure_class = p_structure_class)
    AND  (p_structure_type IS NULL OR s.structure_type = p_structure_type)
    AND  (p_land_zone IS NULL OR s.land_zone = p_land_zone)
    AND  (p_protected IS NULL OR COALESCE(s.protected,false) = p_protected)
    AND  (p_followup_flag IS NULL OR COALESCE(s.followup_flag,false) = p_followup_flag)
    AND  (p_has_replacement IS NULL OR (s.replacement_structure_id IS NOT NULL) = p_has_replacement);
END;
$$;

commit;
