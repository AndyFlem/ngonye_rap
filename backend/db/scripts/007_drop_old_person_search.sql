-- Drop the old 10-parameter overload of a_person_search (superseded by 006)
DROP FUNCTION IF EXISTS public.a_person_search(
  character varying,
  character varying,
  character varying,
  character varying,
  character varying,
  boolean,
  boolean,
  boolean,
  boolean,
  boolean
);
