-- Add p_is_deceased parameter to a_person_search
CREATE OR REPLACE FUNCTION public.a_person_search(
  p_name character varying DEFAULT NULL::character varying,
  p_nrc character varying DEFAULT NULL::character varying,
  p_nhs character varying DEFAULT NULL::character varying,
  p_pah character varying DEFAULT NULL::character varying,
  p_gender character varying DEFAULT NULL::character varying,
  p_is_fisher boolean DEFAULT NULL::boolean,
  p_is_head boolean DEFAULT NULL::boolean,
  p_is_cosignatory boolean DEFAULT NULL::boolean,
  p_is_disabled boolean DEFAULT NULL::boolean,
  p_has_photo boolean DEFAULT NULL::boolean,
  p_is_deceased boolean DEFAULT NULL::boolean
)
RETURNS TABLE(person_id bigint)
LANGUAGE plpgsql
AS $function$
BEGIN
  RETURN QUERY
  SELECT p.person_id
  FROM   v_person p
  WHERE
    (p_nrc IS NULL OR p.nrc ILIKE '%' || p_nrc || '%') AND
    (p_nhs IS NULL OR p.nhs ILIKE '%' || p_nhs || '%') AND
    (p_pah IS NULL OR p.pah ILIKE '%' || p_pah || '%') AND
    (p_gender IS NULL OR p.gender = p_gender) AND
    (p_is_fisher IS NULL OR COALESCE(p.fisher,false) = p_is_fisher) AND
    (p_is_head IS NULL OR COALESCE(p.household_head,false) = p_is_head) AND
    (p_is_cosignatory IS NULL OR COALESCE(p.cosignatory,false) = p_is_cosignatory) AND
    (p_is_disabled IS NULL OR COALESCE(p.disabled,false) = p_is_disabled) AND
    (p_has_photo IS NULL OR (p.photo_file IS NOT NULL) = p_has_photo) AND
    (p_is_deceased IS NULL OR (p.deceased_date IS NOT NULL) = p_is_deceased) AND
    (
      p_name IS NULL OR
      SIMILARITY(p.firstname, p_name) > 0.4 OR
      SIMILARITY(p.lastname,  p_name) > 0.4
    )
  ORDER BY p.lastname, p.firstname;
END
$function$;
