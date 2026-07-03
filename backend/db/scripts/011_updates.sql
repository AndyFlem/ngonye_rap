begin;

DROP FUNCTION public.a_replacements_search(
  character varying,
  character varying,
  character varying,
  character varying,
  character varying,
  boolean,
  boolean,
  character varying
);

update replacement_structures set phase='Group 2' where replacement_structure_id='RST105';

commit;
