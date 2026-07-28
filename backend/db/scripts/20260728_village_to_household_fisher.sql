--
-- Move village_id from person up to households and fishers.
--
-- Village was stored per-person, so nothing guaranteed that the members of a
-- household shared a village. It now lives on households (seeded from the
-- household head) and on fishers (seeded from the linked person's fishing
-- village of record, falling back to their ordinary village), and is dropped
-- from person entirely.
--

BEGIN;

--
-- 1. Columns and data
--

ALTER TABLE public.households
  ADD COLUMN village_id bigint REFERENCES public.villages(village_id);

ALTER TABLE public.fishers
  ADD COLUMN village_id bigint REFERENCES public.villages(village_id);

UPDATE public.households h
   SET village_id = p.village_id
  FROM public.person p
 WHERE h.householdhead_id = p.person_id;

UPDATE public.fishers f
   SET village_id = COALESCE(p.fisher_village_id, p.village_id)
  FROM public.person p
 WHERE f.person_id = p.person_id;

--
-- 2. Views
--

-- v_person loses village_id/village. Removing columns needs a real DROP, which
-- takes v_grievances (its only dependent) with it; v_grievances is recreated
-- below unchanged.
DROP VIEW public.v_grievances;
DROP VIEW public.v_person;

CREATE VIEW public.v_person AS
 SELECT p.person_id,
    p.pah,
    f.nhs,
    p.household_head,
    p.cosignatory,
    p.firstname,
    p.middlename,
    p.lastname,
    concat(p.lastname, ', ', concat_ws(' '::text, p.firstname, p.middlename)) AS fullname,
    p.nrc,
    p.contact,
    p.contact2,
    p.gender,
    p.year_of_birth,
    p.relationship,
    p.marital_status,
    p.pregnant_this_year,
    p.residential_status,
    p.education,
    p.primary_occupation,
    p.secondary_occupation,
    p.primary_skill,
    p.secondary_skill,
    p.disabled,
    p.disabilities,
    p.district,
    p.origin,
    p.photo_file,
    p.deceased_date
   FROM public.person p
     LEFT JOIN public.fishers f ON p.person_id = f.person_id;

CREATE VIEW public.v_grievances AS
 SELECT g.grievance_id,
    g.person_id,
    h.pah,
    f.nhs,
    g.grievance_link,
    g.is_current,
    g.user_id,
    g.created_at,
    g.grievance_ref,
    g.date_received,
    vf.fullname AS person_name
   FROM public.grievances g
     LEFT JOIN public.households h ON g.person_id = h.householdhead_id
     LEFT JOIN public.fishers f ON g.person_id = f.person_id
     LEFT JOIN public.v_person vf ON g.person_id = vf.person_id;

-- v_households: village now comes from the household itself. The join to
-- villages also becomes a LEFT JOIN so households whose head had no village
-- (8 rows) stop being silently excluded from the view.
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
    h.village_id,
    v.village,
    h.linked_pah,
    h.ica_type,
    i.date_signed,
    i.ica_link,
    h.landholding_only,
    (EXISTS ( SELECT true AS bool
           FROM public.structures s
          WHERE s.pah::text = h.pah::text AND s.protected = false)) AS physically_displaced,
    h.vulnerable,
    h.silumesii,
    h.followup_flag AS household_followup_flag,
    h.duplicate_pah,
    h.new_ica_required,
    (EXISTS ( SELECT true AS bool
           FROM public.structures s
          WHERE s.pah::text = h.pah::text AND s.protected = true)) AS has_protected,
    (EXISTS ( SELECT 1
           FROM public.households_survey hs
          WHERE hs.pah = h.pah::text)) AS survey_complete,
    h.allowance_disturbance,
    h.allowance_transport,
    h.allowance_transitional,
    h.allowance_business,
    h.allowance_rental,
    COALESCE(( SELECT sum(p.prep_allowance) AS sum
           FROM public.v_land_assets p
          WHERE p.pah::text = h.pah::text), 0::numeric) AS allowance_landprep,
    h.lr_agricultural,
    h.lr_livestock,
    h.lr_water,
    h.lr_fisheries,
    h.lr_reedbeds,
    h.lr_agricultureinputs,
    h.confidential,
    h.icaoption_primary_structure,
    h.icaoption_landholding,
    h.icaoption_structure_location,
    h.icaoption_dryland,
    h.icaoption_garden,
    h.icaoption_transport,
    COALESCE(h.allowance_disturbance, 0::numeric) + COALESCE(h.allowance_transport, 0::numeric) + COALESCE(h.allowance_transitional, 0::numeric) + COALESCE(h.allowance_business, 0::numeric) + COALESCE(h.allowance_rental, 0::numeric) + COALESCE(( SELECT sum(p.prep_allowance) AS sum
           FROM public.v_land_assets p
          WHERE p.pah::text = h.pah::text), 0::numeric) AS allowance_total,
    ( SELECT count(*) AS count
           FROM public.structures s
          WHERE s.pah::text = h.pah::text) AS structures_count,
    ( SELECT count(*) AS count
           FROM public.structures s
          WHERE s.pah::text = h.pah::text AND s.structure_class::text = 'Primary Structure'::text) AS primary_structures_count,
    ( SELECT count(*) AS count
           FROM public.structures s
          WHERE s.pah::text = h.pah::text AND s.structure_class::text = 'Secondary Structure'::text) AS secondary_structures_count,
    ( SELECT count(*) AS count
           FROM public.replacement_structures rs
          WHERE rs.pah::text = h.pah::text) AS replacement_structures_count,
    ( SELECT sum(s.secondary_compensation_value) AS sum
           FROM public.v_structures s
          WHERE s.pah::text = h.pah::text) AS secondary_structures_compensation_value,
    ( SELECT sum(s.primary_compensation_value) AS sum
           FROM public.v_structures s
          WHERE s.pah::text = h.pah::text) AS primary_structures_compensation_value,
    ( SELECT sum(s.replacement_value) AS sum
           FROM public.v_replacement_structures s
          WHERE s.pah::text = h.pah::text) AS replacement_structures_value,
    hla.lease_cost_total,
    hla.permanent_land_area,
    hla.permanent_land_value,
    hla.land_compensation_value,
    hla.replacement_land_area,
    ( SELECT sum(ts.compensation) AS sum
           FROM public.v_trees_summary ts
          WHERE ts.pah::text = h.pah::text) AS trees_compensation,
    ( SELECT sum(ts.replacement_saplings) AS sum
           FROM public.v_trees_summary ts
          WHERE ts.pah::text = h.pah::text) AS replacement_saplings,
    ( SELECT sum(cp.crop_size) AS sum
           FROM public.v_crops cp
          WHERE cp.pah::text = h.pah::text) AS crop_size,
    ( SELECT sum(cp.crop_value) AS sum
           FROM public.v_crops cp
          WHERE cp.pah::text = h.pah::text) AS crop_value,
    ( SELECT sum(s.primary_value) AS sum
           FROM public.v_structures s
          WHERE s.pah::text = h.pah::text) AS primary_structures_value,
    h.sdate_structures,
    h.sdate_landholdings,
    h.sdate_gardensdryland
   FROM public.households h
     LEFT JOIN public.person ph ON h.householdhead_id = ph.person_id
     LEFT JOIN public.person pc ON h.cosignatory_id = pc.person_id
     LEFT JOIN public.villages v ON h.village_id = v.village_id
     LEFT JOIN public.v_households_land_assets hla ON h.pah::text = hla.pah::text
     LEFT JOIN public.icas i ON h.pah::text = i.pah::text AND i.is_current = true;

-- v_fishers: village now comes from the fisher record.
CREATE OR REPLACE VIEW public.v_fishers AS
 SELECT f.nhs,
    f.person_id,
    concat(ph.lastname, ', ', concat_ws(' '::text, ph.firstname, ph.middlename)) AS fullname,
    f.survey_phase,
    f.social_survey,
    f.catch_survey,
    f.catch_data_survey,
    f.type,
    f.maungwe_active,
    f.maungwe_annual_earnings,
    f.maungwe_traps,
    f.limbelo_active,
    f.limbelo_annual_earnings,
    f.limbelo_traps,
    f.limbelo_annual_buckets,
    f.limbelo_days_fished,
    ((COALESCE(f.limbelo_traps, 0) + COALESCE(f.maungwe_traps, 0)) * 2)::numeric * 12.5 AS site_compensation_calc,
    GREATEST(((COALESCE(f.limbelo_traps, 0) + COALESCE(f.maungwe_traps, 0)) * 2)::numeric * 12.5, 500::numeric) AS site_compensation,
        CASE
            WHEN f.maungwe_active::text = 'Active'::text THEN COALESCE(f.maungwe_traps, 0) * 1500
            ELSE 0
        END AS maungwe_annual_earn,
    COALESCE(f.limbelo_annual_buckets, 0::numeric) AS limbelo_annual_earn,
        CASE
            WHEN f.maungwe_active::text = 'Active'::text THEN COALESCE(f.maungwe_traps, 0) * 1500
            ELSE 0
        END::numeric + COALESCE(f.limbelo_annual_buckets, 0::numeric) * 332::numeric AS transitional_allowance,
    GREATEST(((COALESCE(f.limbelo_traps, 0) + COALESCE(f.maungwe_traps, 0)) * 2)::numeric * 12.5, 500::numeric) +
        CASE
            WHEN f.maungwe_active::text = 'Active'::text THEN COALESCE(f.maungwe_traps, 0) * 1500
            ELSE 0
        END::numeric + COALESCE(f.limbelo_annual_buckets, 0::numeric) * 332::numeric AS total_compensation,
    i.date_signed,
    i.ica_link,
    f.new_ica_required,
    f.followup_flag,
    ph.pah AS linked_pah,
    f.lr_fishfarming,
    f.lr_goatrearing,
    ph.contact,
    ph.nrc,
    f.village_id,
    v.village
   FROM public.fishers f
     JOIN public.person ph ON f.person_id = ph.person_id
     LEFT JOIN public.icas i ON f.nhs::text = i.nhs::text AND i.is_current = true
     LEFT JOIN public.villages v ON f.village_id = v.village_id;

-- v_land_parcels: village now comes from the household. The join to person only
-- existed to reach the head's village, so it goes.
CREATE OR REPLACE VIEW public.v_land_parcels AS
 SELECT lp.land_parcel_id,
    lp.pah,
    lp.land_class,
    lp.cultivated,
    lp.land_zone,
    lp.qaqc_note,
    lp.qaqc_action,
    lp.area_sqm,
    public.st_asgeojson(public.st_transform(lpg.centroid, 4326)) AS centroid,
    ( SELECT sum(la.area_sqm) AS sum
           FROM public.v_land_assets la
          WHERE la.land_parcel_id::text = lp.land_parcel_id::text AND la.acquisition_class::text <> 'None'::text) AS area_acquired,
    lp.remaining_viable,
    ( SELECT sum(COALESCE(la.lease_cost_total, 0::numeric) + COALESCE(la.compensation_value, 0::numeric)) AS sum
           FROM public.v_land_assets la
          WHERE la.land_parcel_id::text = lp.land_parcel_id::text) AS cash_cost_total,
    ( SELECT sum(COALESCE(la.replacement_land_area, 0::numeric)) AS sum
           FROM public.v_land_assets la
          WHERE la.land_parcel_id::text = lp.land_parcel_id::text) AS replacement_land_area,
    h.householdhead_id,
    v.village
   FROM public.land_parcels lp
     JOIN public.land_parcels_geom lpg ON lp.land_parcel_id::text = lpg.land_parcel_id::text
     JOIN public.households h ON lp.pah::text = h.pah::text
     LEFT JOIN public.villages v ON h.village_id = v.village_id;

--
-- 3. Search functions
--

-- a_fishers_search gains p_village_id. A defaulted parameter would create an
-- overload rather than replace, so the old signature is dropped first.
DROP FUNCTION public.a_fishers_search(character varying, character varying, character varying, character varying, integer, boolean, boolean, character varying, character varying, boolean, boolean, boolean, boolean, boolean, boolean, boolean);

CREATE FUNCTION public.a_fishers_search(
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
    p_has_grievances boolean DEFAULT NULL::boolean,
    p_village_id bigint DEFAULT NULL::bigint
) RETURNS TABLE(nhs character varying)
    LANGUAGE plpgsql
    AS $$
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
    (p_village_id IS NULL OR f.village_id = p_village_id) AND
    (p_followup_flag IS NULL OR COALESCE(f.followup_flag,false) = p_followup_flag) AND
    (p_ica_signed IS NULL OR (i.date_signed IS NOT NULL) = p_ica_signed) AND
    (p_new_ica_required IS NULL OR COALESCE(f.new_ica_required,false) = p_new_ica_required) AND
    (p_has_multiple_icas IS NULL OR ((SELECT COUNT(*) FROM public.icas WHERE icas.nhs = f.nhs) > 1) = p_has_multiple_icas) AND
    (p_has_linked_household IS NULL OR (p.pah IS NOT NULL) = p_has_linked_household) AND
    (p_has_notes IS NULL OR (EXISTS (SELECT 1 FROM public.notes n WHERE n.nhs = f.nhs)) = p_has_notes) AND
    (p_has_grievances IS NULL OR (EXISTS (SELECT 1 FROM public.v_grievances g WHERE g.nhs = f.nhs AND g.is_current = true)) = p_has_grievances) AND
    (
      p_name IS NULL OR
      SIMILARITY(p.firstname, p_name) > 0.4 OR
      SIMILARITY(p.lastname,  p_name) > 0.4
    )
  ORDER BY f.nhs;
END
$$;

--
-- 4. Drop the old person columns
--

ALTER TABLE public.person
  DROP COLUMN village_id,
  DROP COLUMN fisher_village_id;

COMMIT;
