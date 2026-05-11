-- Replace v_households to source date_signed and ica_link from the icas table
-- (is_current = true row) instead of directly from households columns.
-- Column names, types, and order are preserved so dependent objects (v_household_compensation,
-- a_households_search) require no changes.

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
          WHERE (hs.pah = (h.pah)::text))) AS survey_complete
   FROM ((((public.households h
     LEFT JOIN public.person ph ON ((h.householdhead_id = ph.person_id)))
     LEFT JOIN public.person pc ON ((h.cosignatory_id = pc.person_id)))
     JOIN public.villages v ON ((h.village_id = v.village_id)))
     LEFT JOIN public.v_households_land_assets hla ON (((h.pah)::text = (hla.pah)::text)))
     LEFT JOIN public.icas i ON (h.pah = i.pah AND i.is_current = true);

-- Drop the now-redundant columns from households
ALTER TABLE public.households DROP COLUMN date_signed;
ALTER TABLE public.households DROP COLUMN ica_link;
