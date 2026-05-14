-- Drop old overloads of search functions that lack the p_has_notes parameter

DROP FUNCTION IF EXISTS public.a_households_search(
  character varying, character varying, boolean, boolean, boolean, boolean,
  boolean, boolean, boolean, boolean, boolean, character varying, bigint,
  character varying, character varying, character varying, character varying,
  character varying, character varying, boolean, boolean, boolean, boolean,
  boolean, boolean, boolean
);

DROP FUNCTION IF EXISTS public.a_fishers_search(
  character varying, character varying, character varying, character varying,
  integer, boolean, boolean, character varying, character varying, boolean,
  boolean, boolean, boolean, boolean
);
