-- Drop the old a_person_search overload that lacks p_has_photo
DROP FUNCTION IF EXISTS public.a_person_search(
  character varying, character varying, character varying, character varying,
  character varying, boolean, boolean, boolean, boolean
);
