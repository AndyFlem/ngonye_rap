-- Drop the old 10-parameter overload of a_fishers_search (superseded by 017)
DROP FUNCTION IF EXISTS public.a_fishers_search(
  character varying, character varying, character varying, character varying,
  integer, boolean, boolean, character varying, character varying, boolean
);
