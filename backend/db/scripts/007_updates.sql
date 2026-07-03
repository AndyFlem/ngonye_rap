begin;

ALTER TABLE IF EXISTS public.replacement_structure_types
    ADD COLUMN replacement_cost_2024 numeric(12, 2);

update replacement_structure_types set replacement_cost_2024=10750 where replacement_type_ref='Cat A';
update replacement_structure_types set replacement_cost_2024=14000 where replacement_type_ref='Cat B';
update replacement_structure_types set replacement_cost_2024=17500 where replacement_type_ref='Cat C';
update replacement_structure_types set replacement_cost_2024=20000 where replacement_type_ref='Cat D';
update replacement_structure_types set replacement_cost_2024=22750 where replacement_type_ref='Cat E';
update replacement_structure_types set replacement_cost_2024=27000 where replacement_type_ref='Cat F';

update replacement_structure_types set replacement_cost_2024=35250 where replacement_type_ref='Shop';



CREATE OR REPLACE FUNCTION public.a_fishers_search(
	p_name character varying DEFAULT NULL::character varying,
	p_nhs character varying DEFAULT NULL::character varying,
	p_nrc character varying DEFAULT NULL::character varying,
	p_type character varying DEFAULT NULL::character varying,
	p_survey_phase integer DEFAULT NULL::integer,
	p_social_survey boolean DEFAULT NULL::boolean,
	p_catch_survey boolean DEFAULT NULL::boolean,
	p_maungwe_active character varying DEFAULT NULL::character varying,
	p_limbelo_active character varying DEFAULT NULL::character varying,
	p_followup_flag boolean DEFAULT NULL::boolean,
	p_ica_signed boolean DEFAULT NULL::boolean,
	p_new_ica_required boolean DEFAULT NULL::boolean,
	p_has_multiple_icas boolean DEFAULT NULL::boolean,
	p_has_linked_household boolean DEFAULT NULL::boolean,
	p_has_notes boolean DEFAULT NULL::boolean,
	p_has_grievances boolean DEFAULT NULL::boolean)
    RETURNS TABLE(nhs character varying) 
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
    ROWS 1000

AS $BODY$
BEGIN
  RETURN QUERY
  SELECT f.nhs
  FROM   public.fishers f
  LEFT JOIN public.person p ON f.person_id = p.person_id
  LEFT JOIN public.icas i ON f.nhs = i.nhs AND i.is_current = true
  WHERE
    (p_nhs IS NULL OR f.nhs ILIKE '%' || p_nhs || '%') AND
    (p_nrc IS NULL OR p.nrc ILIKE '%' || p_nrc || '%') AND
    (p_type IS NULL OR f.type = p_type) AND
    (p_survey_phase IS NULL OR f.survey_phase = p_survey_phase) AND
    (p_social_survey IS NULL OR f.social_survey = p_social_survey) AND
    (p_catch_survey IS NULL OR f.catch_survey = p_catch_survey) AND
    (p_maungwe_active IS NULL OR f.maungwe_active = p_maungwe_active) AND
    (p_limbelo_active IS NULL OR f.limbelo_active = p_limbelo_active) AND
    (p_followup_flag IS NULL OR COALESCE(f.followup_flag,false) = p_followup_flag) AND
    (p_ica_signed IS NULL OR (i.date_signed IS NOT NULL) = p_ica_signed) AND
    (p_new_ica_required IS NULL OR COALESCE(f.new_ica_required,false) = p_new_ica_required) AND
    (p_has_multiple_icas IS NULL OR ((SELECT COUNT(*) FROM public.icas WHERE icas.nhs = f.nhs) > 1) = p_has_multiple_icas) AND
    (p_has_linked_household IS NULL OR (p.pah IS NOT NULL) = p_has_linked_household) AND
    (p_has_notes IS NULL OR (EXISTS (SELECT 1 FROM public.notes n WHERE n.nhs = f.nhs)) = p_has_notes) AND
    (p_has_grievances IS NULL OR (EXISTS (SELECT 1 FROM public.grievances g WHERE g.nhs = f.nhs)) = p_has_grievances) AND
    (
      p_name IS NULL OR
      SIMILARITY(p.firstname, p_name) > 0.4 OR
      SIMILARITY(p.lastname,  p_name) > 0.4
    )
  ORDER BY f.nhs;
END
$BODY$;

ALTER FUNCTION public.a_fishers_search(character varying, character varying, character varying, character varying, integer, boolean, boolean, character varying, character varying, boolean, boolean, boolean, boolean, boolean, boolean, boolean)
    OWNER TO postgres;


CREATE OR REPLACE FUNCTION public.a_replacements_search(
	p_pah character varying DEFAULT NULL::character varying,
	p_replacement_structure_id character varying DEFAULT NULL::character varying,
	p_replacement_option character varying DEFAULT NULL::character varying,
	p_replacement_class character varying DEFAULT NULL::character varying,
	p_icaoption_structure_location character varying DEFAULT NULL::character varying,
	p_protected boolean DEFAULT NULL::boolean,
	p_flag_followup boolean DEFAULT NULL::boolean,
	p_phase character varying DEFAULT NULL::character varying)
    RETURNS TABLE(replacement_structure_id character varying, pah character varying) 
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
    ROWS 1000

AS $BODY$
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
    AND  (p_phase IS NULL OR rs.phase = p_phase);
END;
$BODY$;

ALTER FUNCTION public.a_replacements_search(character varying, character varying, character varying, character varying, character varying, boolean, boolean, character varying)
    OWNER TO postgres;

-- View: public.v_replacement_structures

-- DROP VIEW public.v_replacement_structures;

CREATE OR REPLACE VIEW public.v_replacement_structures
 AS
 SELECT rs.replacement_structure_id,
    rs.pah,
    rs.phase,
    rs.data_notes,
    rs.structure_id,
    rs.flag_followup,
    rs.replacement_type_ref,
    rst.replacement_class,
    rst.replacement_option,
    rst.replacement_value,
    h.icaoption_primary_structure,
    h.icaoption_structure_location,
    s.protected,
    h.householdhead_id,
	rst.replacement_cost_2024
   FROM replacement_structures rs
     JOIN replacement_structure_types rst ON rs.replacement_type_ref::text = rst.replacement_type_ref::text
     JOIN households h ON rs.pah::text = h.pah::text
     LEFT JOIN structures s ON rs.structure_id::text = s.structure_id::text;

ALTER TABLE public.v_replacement_structures
    OWNER TO postgres;

update public.replacement_structure_types set replacement_type_ref='Cath Church' where replacement_type_ref='Cath Chrch';
update public.replacement_structure_types set replacement_type_ref='SDA Church' where replacement_type_ref='SDA Chrch';
update public.replacement_structures set replacement_type_ref='Cath Church' where replacement_type_ref='Cath Chrch';
update public.replacement_structures set replacement_type_ref='SDA Church' where replacement_type_ref='SDA Chrch';


-- View: public.v_replacement_structures

-- DROP VIEW public.v_replacement_structures;

CREATE OR REPLACE VIEW public.v_replacement_structures
 AS
 SELECT rs.replacement_structure_id,
    rs.pah,
    rs.phase,
    rs.data_notes,
    rs.structure_id,
    rs.flag_followup,
    rs.replacement_type_ref,
    rst.replacement_class,
    rst.replacement_option,
    rst.replacement_value,
    h.icaoption_primary_structure,
    h.icaoption_structure_location,
    s.protected,
    h.householdhead_id,
    rst.replacement_cost_2024
   FROM replacement_structures rs
     JOIN replacement_structure_types rst ON rs.replacement_type_ref::text = rst.replacement_type_ref::text
     LEFT JOIN households h ON rs.pah::text = h.pah::text
     LEFT JOIN structures s ON rs.structure_id::text = s.structure_id::text;

ALTER TABLE public.v_replacement_structures
    OWNER TO postgres;

update replacement_structure_types set replacement_cost_2024=26500 where replacement_type_ref='Cath Church';
update replacement_structure_types set replacement_cost_2024=26500 where replacement_type_ref='SDA Church';

UPDATE households h 
set icaoption_structure_location='1: Self-Source'
where
silumesii=true;

UPDATE households h 
set icaoption_structure_location='3: Project - Host Site'
where
pah='PAH047';
UPDATE households h 
set icaoption_primary_structure='1: Replacement Housing'
where
pah='PAH903' or pah='PAH904';

update replacement_structures set phase='Group 1' where phase='Phase 1 Group 1';
update replacement_structures set phase='Group 2' where phase='Phase 1 Group 2';
update replacement_structures set phase='Group 3' where phase='Phase 3';
commit;