begin;

CREATE OR REPLACE VIEW public.v_replacement_structures
 AS
 SELECT rs.replacement_structure_id,
    rs.pah,
    rs.phase,
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
    rst.replacement_cost_2024,
	h.silumesii
   FROM replacement_structures rs
     JOIN replacement_structure_types rst ON rs.replacement_type_ref::text = rst.replacement_type_ref::text
     LEFT JOIN households h ON rs.pah::text = h.pah::text
     LEFT JOIN structures s ON rs.structure_id::text = s.structure_id::text;

ALTER TABLE public.v_replacement_structures
    OWNER TO postgres;

commit;