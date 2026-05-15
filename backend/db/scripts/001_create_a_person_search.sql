-- Creates the a_person_search function used by the People search feature.

DROP FUNCTION IF EXISTS public.a_person_search(varchar,varchar,varchar,varchar,varchar,boolean,boolean,boolean,boolean);

CREATE OR REPLACE FUNCTION public.a_person_search(
  p_name           varchar DEFAULT NULL,
  p_nrc            varchar DEFAULT NULL,
  p_nhs            varchar DEFAULT NULL,
  p_pah            varchar DEFAULT NULL,
  p_gender         varchar DEFAULT NULL,
  p_is_fisher      boolean DEFAULT NULL,
  p_is_head        boolean DEFAULT NULL,
  p_is_cosignatory boolean DEFAULT NULL,
  p_is_disabled    boolean DEFAULT NULL
) RETURNS TABLE(person_id bigint)
LANGUAGE plpgsql AS $$
BEGIN
  RETURN QUERY
  SELECT p.person_id
  FROM   public.person p
  WHERE
    (p_nrc IS NULL OR p.nrc ILIKE '%' || p_nrc || '%') AND
    (p_nhs IS NULL OR p.nhs ILIKE '%' || p_nhs || '%') AND
    (p_pah IS NULL OR p.pah ILIKE '%' || p_pah || '%') AND
    (p_gender IS NULL OR p.gender = p_gender) AND
    (p_is_fisher IS NULL OR p.fisher = p_is_fisher) AND
    (p_is_head IS NULL OR p.household_head = p_is_head) AND
    (p_is_cosignatory IS NULL OR p.cosignatory = p_is_cosignatory) AND
    (p_is_disabled IS NULL OR p.disabled = p_is_disabled) AND
    (
      p_name IS NULL OR
      SIMILARITY(p.firstname, p_name) > 0.4 OR
      SIMILARITY(p.lastname,  p_name) > 0.4
    )
  ORDER BY p.lastname, p.firstname;
END
$$;
