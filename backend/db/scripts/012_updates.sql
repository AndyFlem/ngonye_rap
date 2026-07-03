begin;

-- 1. Add duplicate_pah column to households
ALTER TABLE public.households ADD COLUMN duplicate_pah character varying(20);

-- 2. Update v_households view to expose duplicate_pah
CREATE OR REPLACE VIEW public.v_households AS
 SELECT h.pah,
    h.householdhead_id,
    ph.firstname,
    ph.middlename,
    ph.lastname,
    h.cosignatory_id,
    concat(ph.lastname, ', ', concat_ws(' '::text, ph.firstname, ph.middlename)) AS fullname,
    ph.nrc,
    ph.contact,
    concat(pc.lastname, ', ', concat_ws(' '::text, pc.firstname, pc.middlename)) AS cosignatory_fullname,
    pc.nrc AS cosignatory_nrc,
    pc.contact AS cosignatory_contact,
    h.linked_pah,
    h.landholding_only,
    h.allowance_disturbance,
    h.allowance_transport,
    h.allowance_transitional,
    h.allowance_business,
    h.allowance_rental,
    COALESCE(( SELECT sum(p.prep_allowance) AS sum
           FROM public.v_land_assets p
          WHERE ((p.pah)::text = (h.pah)::text)), (0)::numeric) AS allowance_landprep,
    h.lr_agricultural,
    h.lr_livestock,
    h.lr_water,
    h.lr_fisheries,
    h.lr_reedbeds,
    h.lr_agricultureinputs,
    h.vulnerable,
    i.date_signed,
    h.no_ica_required,
    i.ica_link,
    h.nonaffected,
    h.silumesii,
    h.followup_flag AS household_followup_flag,
    h.physically_displaced,
    h.new_ica_required,
    v.village_id,
    v.village,
    h.icaoption_primary_structure,
    h.icaoption_landholding,
    h.icaoption_structure_location,
    h.icaoption_dryland,
    h.icaoption_garden,
    h.icaoption_transport,
    (((((COALESCE(h.allowance_disturbance, (0)::numeric) + COALESCE(h.allowance_transport, (0)::numeric)) + COALESCE(h.allowance_transitional, (0)::numeric)) + COALESCE(h.allowance_business, (0)::numeric)) + COALESCE(h.allowance_rental, (0)::numeric)) + COALESCE(( SELECT sum(p.prep_allowance) AS sum
           FROM public.v_land_assets p
          WHERE ((p.pah)::text = (h.pah)::text)), (0)::numeric)) AS allowance_total,
    ( SELECT count(*) AS count
           FROM public.structures s
          WHERE ((s.pah)::text = (h.pah)::text)) AS structures_count,
    ( SELECT count(*) AS count
           FROM public.structures s
          WHERE (((s.pah)::text = (h.pah)::text) AND ((s.structure_class)::text = 'Primary Structure'::text))) AS primary_structures_count,
    ( SELECT count(*) AS count
           FROM public.structures s
          WHERE (((s.pah)::text = (h.pah)::text) AND ((s.structure_class)::text = 'Secondary Structure'::text))) AS secondary_structures_count,
    ( SELECT count(*) AS count
           FROM public.replacement_structures rs
          WHERE ((rs.pah)::text = (h.pah)::text)) AS replacement_structures_count,
    ( SELECT sum(s.secondary_compensation_value) AS sum
           FROM public.v_structures s
          WHERE ((s.pah)::text = (h.pah)::text)) AS secondary_structures_compensation_value,
    ( SELECT sum(s.primary_compensation_value) AS sum
           FROM public.v_structures s
          WHERE ((s.pah)::text = (h.pah)::text)) AS primary_structures_compensation_value,
    ( SELECT sum(s.replacement_value) AS sum
           FROM public.v_replacement_structures s
          WHERE ((s.pah)::text = (h.pah)::text)) AS replacement_structures_value,
    hla.lease_cost_total,
    hla.permanent_land_area,
    hla.permanent_land_value,
    hla.land_compensation_value,
    hla.replacement_land_area,
    ( SELECT sum(ts.compensation) AS sum
           FROM public.v_trees_summary ts
          WHERE ((ts.pah)::text = (h.pah)::text)) AS trees_compensation,
    ( SELECT sum(ts.replacement_saplings) AS sum
           FROM public.v_trees_summary ts
          WHERE ((ts.pah)::text = (h.pah)::text)) AS replacement_saplings,
    ( SELECT sum(cp.crop_size) AS sum
           FROM public.v_crops cp
          WHERE ((cp.pah)::text = (h.pah)::text)) AS crop_size,
    ( SELECT sum(cp.crop_value) AS sum
           FROM public.v_crops cp
          WHERE ((cp.pah)::text = (h.pah)::text)) AS crop_value,
    (EXISTS ( SELECT true AS bool
           FROM public.structures s
          WHERE (((s.pah)::text = (h.pah)::text) AND (s.protected = true)))) AS has_protected,
    (EXISTS ( SELECT 1
           FROM public.households_survey hs
          WHERE (hs.pah = (h.pah)::text))) AS survey_complete,
    h.duplicate_pah
   FROM (((((public.households h
     LEFT JOIN public.person ph ON ((h.householdhead_id = ph.person_id)))
     LEFT JOIN public.person pc ON ((h.cosignatory_id = pc.person_id)))
     JOIN public.villages v ON ((h.village_id = v.village_id)))
     LEFT JOIN public.v_households_land_assets hla ON (((h.pah)::text = (hla.pah)::text)))
     LEFT JOIN public.icas i ON ((((h.pah)::text = (i.pah)::text) AND (i.is_current = true))));

-- 3. Drop and recreate a_households_search with p_is_duplicate parameter
DROP FUNCTION public.a_households_search(character varying, character varying, boolean, boolean, boolean, boolean, boolean, boolean, boolean, boolean, boolean, character varying, bigint, character varying, character varying, character varying, character varying, character varying, character varying, boolean, boolean, boolean, boolean, boolean, boolean, boolean, boolean);

CREATE OR REPLACE FUNCTION public.a_households_search(p_household_head character varying DEFAULT NULL::character varying, p_pah character varying DEFAULT NULL::character varying, p_vulnerable boolean DEFAULT NULL::boolean, p_nonaffected boolean DEFAULT NULL::boolean, p_landholding_only boolean DEFAULT NULL::boolean, p_silumesii boolean DEFAULT NULL::boolean, p_new_ica_required boolean DEFAULT NULL::boolean, p_no_ica_required boolean DEFAULT NULL::boolean, p_icasigned boolean DEFAULT NULL::boolean, p_followup_flag boolean DEFAULT NULL::boolean, p_physically_displaced boolean DEFAULT NULL::boolean, p_nrc character varying DEFAULT NULL::character varying, p_village_id bigint DEFAULT NULL::bigint, p_icaoption_primary_structure character varying DEFAULT NULL::character varying, p_icaoption_structure_location character varying DEFAULT NULL::character varying, p_icaoption_landholding character varying DEFAULT NULL::character varying, p_icaoption_dryland character varying DEFAULT NULL::character varying, p_icaoption_garden character varying DEFAULT NULL::character varying, p_icaoption_transport character varying DEFAULT NULL::character varying, p_has_replacement_structures boolean DEFAULT NULL::boolean, p_has_replacement_land boolean DEFAULT NULL::boolean, p_has_protected boolean DEFAULT NULL::boolean, p_survey_complete boolean DEFAULT NULL::boolean, p_has_current_grievance boolean DEFAULT NULL::boolean, p_has_multiple_icas boolean DEFAULT NULL::boolean, p_has_linked_fisher boolean DEFAULT NULL::boolean, p_has_notes boolean DEFAULT NULL::boolean, p_is_duplicate boolean DEFAULT NULL::boolean) RETURNS TABLE(pah character varying, household_head_fullname text, date_signed date)
    LANGUAGE plpgsql
    AS $$
BEGIN
  RETURN QUERY
    SELECT
      h.pah,
      concat(p.lastname, ', ', concat_ws(' '::text, p.firstname, p.middlename)),
      h.date_signed
    FROM
      v_households h
      LEFT JOIN v_household_compensation hc ON h.pah = hc.pah
      LEFT JOIN person p ON h.householdhead_id = p.person_id
    WHERE
      (COALESCE(h.vulnerable,false) = p_vulnerable OR p_vulnerable IS NULL) AND
      (COALESCE(h.nonaffected,false) = p_nonaffected OR p_nonaffected IS NULL) AND
      (COALESCE(h.landholding_only,false) = p_landholding_only OR p_landholding_only IS NULL) AND
      (COALESCE(h.silumesii,false) = p_silumesii OR p_silumesii IS NULL) AND
      (COALESCE(h.new_ica_required,false) = p_new_ica_required OR p_new_ica_required IS NULL) AND
      (COALESCE(h.no_ica_required,false) = p_no_ica_required OR p_no_ica_required IS NULL) AND
      ((h.date_signed IS NULL AND p_icasigned = False) OR (h.date_signed IS NOT NULL AND p_icasigned = True) OR p_icasigned IS NULL) AND
      (COALESCE(h.household_followup_flag,false) = p_followup_flag OR p_followup_flag IS NULL) AND
      (COALESCE(h.physically_displaced,false) = p_physically_displaced OR p_physically_displaced IS NULL) AND
      (h.pah = p_pah OR p_pah IS NULL) AND
      (p.nrc ILIKE '%' || p_nrc || '%' OR p_nrc IS NULL) AND
      (h.village_id = p_village_id OR p_village_id IS NULL) AND
      (h.icaoption_primary_structure = p_icaoption_primary_structure OR p_icaoption_primary_structure IS NULL) AND
      (h.icaoption_structure_location = p_icaoption_structure_location OR p_icaoption_structure_location IS NULL) AND
      (h.icaoption_landholding = p_icaoption_landholding OR p_icaoption_landholding IS NULL) AND
      (h.icaoption_dryland = p_icaoption_dryland OR p_icaoption_dryland IS NULL) AND
      (h.icaoption_garden = p_icaoption_garden OR p_icaoption_garden IS NULL) AND
      (h.icaoption_transport = p_icaoption_transport OR p_icaoption_transport IS NULL) AND
      ((COALESCE(h.replacement_structures_count, 0) > 0) = p_has_replacement_structures OR p_has_replacement_structures IS NULL) AND
      ((COALESCE(h.replacement_land_area, 0) > 0) = p_has_replacement_land OR p_has_replacement_land IS NULL) AND
      (COALESCE(h.has_protected,false) = p_has_protected OR p_has_protected IS NULL) AND
      (COALESCE(h.survey_complete,false) = p_survey_complete OR p_survey_complete IS NULL) AND
      ((EXISTS (SELECT 1 FROM public.v_grievances g WHERE g.pah = h.pah AND g.is_current = true)) = p_has_current_grievance OR p_has_current_grievance IS NULL) AND
      (((SELECT COUNT(*) FROM public.icas WHERE icas.pah = h.pah) > 1) = p_has_multiple_icas OR p_has_multiple_icas IS NULL) AND
      ((EXISTS (SELECT 1 FROM public.v_person pm WHERE pm.pah = h.pah AND pm.nhs IS NOT NULL)) = p_has_linked_fisher OR p_has_linked_fisher IS NULL) AND
      ((EXISTS (SELECT 1 FROM public.notes n WHERE n.pah = h.pah)) = p_has_notes OR p_has_notes IS NULL) AND
      ((h.duplicate_pah IS NOT NULL) = p_is_duplicate OR p_is_duplicate IS NULL) AND
      (
        (SIMILARITY(p.firstname, p_household_head) > 0.4 OR p_household_head IS NULL) OR
        (SIMILARITY(p.lastname, p_household_head) > 0.4 OR p_household_head IS NULL) OR
        (SIMILARITY(p.middlename, p_household_head) > 0.4 OR p_household_head IS NULL)
      )
    ORDER BY h.pah;
END
$$;

commit;
