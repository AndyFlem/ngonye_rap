BEGIN;

CREATE OR REPLACE FUNCTION public.a_fishers_search(
  p_name           character varying DEFAULT NULL,
  p_nhs            character varying DEFAULT NULL,
  p_nrc            character varying DEFAULT NULL,
  p_type           character varying DEFAULT NULL,
  p_survey_phase   integer           DEFAULT NULL,
  p_social_survey  boolean           DEFAULT NULL,
  p_catch_survey   boolean           DEFAULT NULL,
  p_maungwe_active character varying DEFAULT NULL,
  p_limbelo_active character varying DEFAULT NULL
) RETURNS TABLE(nhs varchar)
  LANGUAGE plpgsql
AS $$
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
    (
      p_name IS NULL OR
      SIMILARITY(p.firstname, p_name) > 0.4 OR
      SIMILARITY(p.lastname,  p_name) > 0.4
    )
  ORDER BY f.nhs;
END
$$;

ALTER FUNCTION public.a_fishers_search(
  character varying, character varying, character varying,
  character varying, integer, boolean, boolean,
  character varying, character varying
) OWNER TO postgres;

COMMIT;
