BEGIN;

-- 1. New notes table
CREATE TABLE public.replacement_structure_notes (
    note_id bigserial PRIMARY KEY,
    replacement_structure_id character varying(9) NOT NULL
        REFERENCES public.replacement_structures(replacement_structure_id),
    user_id bigint NOT NULL
        REFERENCES public."user"(user_id),
    note text NOT NULL,
    created_at timestamptz NOT NULL DEFAULT now()
);

-- 2. View with created_by (mirrors v_notes pattern)
CREATE VIEW public.v_replacement_structure_notes AS
SELECT n.note_id,
    n.replacement_structure_id,
    n.user_id,
    n.note,
    n.created_at,
    (u.first_name::text || ' ' || u.last_name::text) AS created_by
FROM public.replacement_structure_notes n
LEFT JOIN public."user" u ON u.user_id = n.user_id;

-- 3. Migrate existing data_notes (attribute to the oldest user as system author)
INSERT INTO public.replacement_structure_notes
    (replacement_structure_id, user_id, note, created_at)
SELECT replacement_structure_id,
       (SELECT MIN(user_id) FROM public."user"),
       data_notes,
       now()
FROM public.replacement_structures
WHERE data_notes IS NOT NULL AND data_notes <> '';

-- 4. Drop dependent views (CASCADE removes v_structures, v_households, v_household_compensation)
DROP VIEW public.v_replacement_structures CASCADE;

-- 5. Drop the old column now that its referencing view is gone
ALTER TABLE public.replacement_structures DROP COLUMN data_notes;

-- 6. Recreate v_replacement_structures without data_notes
CREATE VIEW public.v_replacement_structures AS
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
    rst.replacement_cost_2024
FROM public.replacement_structures rs
JOIN public.replacement_structure_types rst
    ON rs.replacement_type_ref::text = rst.replacement_type_ref::text
LEFT JOIN public.households h ON rs.pah::text = h.pah::text
LEFT JOIN public.structures s ON rs.structure_id::text = s.structure_id::text;

ALTER TABLE public.v_replacement_structures OWNER TO postgres;

-- 7. Recreate v_structures (unchanged definition — just lost due to cascade)
CREATE VIEW public.v_structures AS
 SELECT s.structure_id,
    s.pah,
    s.replacement_structure_id,
    s.land_zone,
    s.structure_class,
    s.structure_type,
    s.secondary_description,
    s.structure_value_adjustment,
    s.dimensions,
    s.rooms,
    s.roof_type,
    s.roof_rate,
    s.roof_value,
    s.floor_type,
    s.floor_rate,
    s.floor_value,
    s.walls_type,
    s.walls_rate,
    s.wall_value,
    s.doors,
    s.doors_type,
    s.doors_rate,
    s.door_value,
    s.windows,
    s.windows_type,
    s.windows_rate,
    s.window_value,
    s.owner_tenant,
    s.owner_name,
    s.secondary_rate,
    s.structure_value,
        CASE
            WHEN ((s.structure_class)::text = 'Secondary Structure'::text) THEN s.structure_value
            ELSE NULL::numeric
        END AS secondary_compensation_value,
        CASE
            WHEN (((s.structure_class)::text = 'Primary Structure'::text) AND (s.replacement_structure_id IS NULL)) THEN s.structure_value
            ELSE NULL::numeric
        END AS primary_compensation_value,
    rs.replacement_class,
    rs.replacement_option,
    rs.replacement_value,
    rs.replacement_type_ref,
    s.followup_flag,
    s.data_notes,
    public.st_asgeojson(public.st_transform(sg.geom, 4326)) AS centroid,
    s.protected
   FROM ((public.structures s
     JOIN public.structures_geom sg ON (((s.structure_id)::text = (sg.structure_id)::text)))
     LEFT JOIN public.v_replacement_structures rs ON (((s.replacement_structure_id)::text = (rs.replacement_structure_id)::text)));

-- 8. Recreate v_households (unchanged definition — lost due to cascade)
CREATE VIEW public.v_households AS
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
   FROM (((((public.households h
     LEFT JOIN public.person ph ON ((h.householdhead_id = ph.person_id)))
     LEFT JOIN public.person pc ON ((h.cosignatory_id = pc.person_id)))
     JOIN public.villages v ON ((h.village_id = v.village_id)))
     LEFT JOIN public.v_households_land_assets hla ON (((h.pah)::text = (hla.pah)::text)))
     LEFT JOIN public.icas i ON ((((h.pah)::text = (i.pah)::text) AND (i.is_current = true))));

-- 9. Recreate v_household_compensation (unchanged definition — lost due to cascade)
CREATE VIEW public.v_household_compensation AS
 SELECT v_households.pah,
    v_households.primary_structures_compensation_value,
    v_households.secondary_structures_compensation_value,
    v_households.allowance_total,
    v_households.lease_cost_total,
    v_households.land_compensation_value,
    v_households.trees_compensation,
    v_households.crop_value,
    ((((((COALESCE(v_households.primary_structures_compensation_value, (0)::numeric) + COALESCE(v_households.secondary_structures_compensation_value, (0)::numeric)) + COALESCE(v_households.allowance_total, (0)::numeric)) + COALESCE(v_households.lease_cost_total, (0)::numeric)) + COALESCE(v_households.land_compensation_value, (0)::numeric)) + COALESCE(v_households.trees_compensation, (0)::numeric)) + COALESCE(v_households.crop_value, (0)::numeric)) AS total_cash_compensation
   FROM public.v_households;

COMMIT;
