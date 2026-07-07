begin;

CREATE OR REPLACE VIEW public.v_household_land_compensation
 AS
 SELECT
    lp.pah,
    lp.land_class,
	la.acquisition_class,
	count(la.land_asset_id) as asset_count,
	sum(la.area_sqm) as area_sqm,
	sum(la.land_value) as land_value,
	sum(la.lease_cost) as lease_cost,
	sum(la.lease_cost * la.lease_years::numeric) AS lease_cost_total,
	max(la.rate_acquisition) as rate_acquisition,
	max(la.rate_lease) as rate_lease
   FROM land_assets la
     JOIN land_parcels lp ON la.land_parcel_id::text = lp.land_parcel_id::text
WHERE 	
	la.acquisition_class<>'None'	 
   GROUP BY
   	lp.pah,
	lp.land_class,
	la.acquisition_class;

ALTER TABLE public.v_household_land_compensation
    OWNER TO postgres;


ALTER TABLE IF EXISTS public.land_assets
    ADD COLUMN rate_acquisition_class character varying(100);

update land_assets set rate_acquisition_class='Landholding: River' where rate_acquisition=2.0;
update land_assets set rate_acquisition_class='Landholding' WHERE rate_acquisition=1.0;
update land_assets set rate_acquisition_class='Dry Land' WHERE rate_acquisition=1.1;
update land_assets set rate_acquisition_class='Garden' WHERE rate_acquisition=2.1;
update land_assets set rate_acquisition_class='Landholding: River 4' WHERE rate_acquisition=4;

update land_parcels set land_class='Landholding' FROM land_assets la WHERE land_parcels.land_parcel_id=la.land_parcel_id
AND
la.rate_acquisition=2.0;
update land_parcels set land_class='Landholding' FROM land_assets la WHERE land_parcels.land_parcel_id=la.land_parcel_id
AND
la.rate_acquisition=1.0;
update land_parcels set land_class='Dry Land' FROM land_assets la WHERE land_parcels.land_parcel_id=la.land_parcel_id
AND
la.rate_acquisition=1.1;
update land_parcels set land_class='Garden' FROM land_assets la WHERE land_parcels.land_parcel_id=la.land_parcel_id
AND
la.rate_acquisition=2.1;
update land_parcels set land_class='Landholding' FROM land_assets la WHERE land_parcels.land_parcel_id=la.land_parcel_id
AND
la.rate_acquisition=4;



DROP VIEW public.v_household_land_compensation;

CREATE OR REPLACE VIEW  public.v_household_land_compensation
 AS
 SELECT lp.pah,
    la.acquisition_class,
    la.rate_acquisition_class,
	lp.cultivated,
    count(la.land_asset_id) AS asset_count,
    sum(la.area_sqm) AS area_sqm,
    sum(la.land_value) AS land_value,
    sum(la.lease_cost) AS lease_cost,
    sum(la.lease_cost * la.lease_years::numeric) AS lease_cost_total,
    max(la.rate_acquisition) AS rate_acquisition,
    max(la.rate_lease) AS rate_lease
   FROM land_assets la
     JOIN land_parcels lp ON la.land_parcel_id::text = lp.land_parcel_id::text
  WHERE la.acquisition_class::text <> 'None'::text
  GROUP BY 
  	lp.pah, 
	la.acquisition_class, 
	la.rate_acquisition_class,
	lp.cultivated;

ALTER TABLE public.v_household_land_compensation
    OWNER TO postgres;


update land_assets set rate_acquisition_class='Temporary Cultivated' from land_parcels lp
where land_assets.land_parcel_id=lp.land_parcel_id and acquisition_class='Temporary' and lp.cultivated=True;

update land_assets set rate_acquisition_class='Temporary Uncultivated' from land_parcels lp
where land_assets.land_parcel_id=lp.land_parcel_id and acquisition_class='Temporary' and lp.cultivated=False;

CREATE OR REPLACE VIEW select * from public.v_household_land_permanent
 AS
 SELECT lp.pah,
    lp.land_class,
    count(la.land_asset_id) AS asset_count,
    sum(la.area_sqm) AS area_sqm,
    sum(la.land_value) AS land_value
   FROM land_assets la
     JOIN land_parcels lp ON la.land_parcel_id::text = lp.land_parcel_id::text
  WHERE la.acquisition_class::text = 'Permanent'::text
  GROUP BY 
  	lp.pah, 
	lp.land_class;

ALTER TABLE public.v_household_land_permanent
    OWNER TO postgres;


CREATE OR REPLACE VIEW public.v_structures
 AS
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
		WHEN s.structure_class::text = 'Secondary Structure'::text THEN s.structure_value
		ELSE NULL::numeric
	END AS secondary_compensation_value,
	CASE
		WHEN s.structure_class::text = 'Primary Structure'::text AND s.replacement_structure_id IS NULL THEN s.structure_value
		ELSE NULL::numeric
	END AS primary_compensation_value,
    rs.replacement_class,
    rs.replacement_option,
    rs.replacement_value,
    rs.replacement_type_ref,
    s.followup_flag,
    s.data_notes,
    st_asgeojson(st_transform(sg.geom, 4326)) AS centroid,
    s.protected,
	CASE
		WHEN s.structure_class::text = 'Primary Structure'::text THEN s.structure_value
		ELSE NULL::numeric
	END AS primary_value
   FROM structures s
     JOIN structures_geom sg ON s.structure_id::text = sg.structure_id::text
     LEFT JOIN v_replacement_structures rs ON s.replacement_structure_id::text = rs.replacement_structure_id::text;

ALTER TABLE public.v_structures
    OWNER TO postgres;


CREATE OR REPLACE VIEW public.v_households
 AS
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
           FROM v_land_assets p
          WHERE p.pah::text = h.pah::text), 0::numeric) AS allowance_landprep,
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
    COALESCE(h.allowance_disturbance, 0::numeric) + COALESCE(h.allowance_transport, 0::numeric) + COALESCE(h.allowance_transitional, 0::numeric) + COALESCE(h.allowance_business, 0::numeric) + COALESCE(h.allowance_rental, 0::numeric) + COALESCE(( SELECT sum(p.prep_allowance) AS sum
           FROM v_land_assets p
          WHERE p.pah::text = h.pah::text), 0::numeric) AS allowance_total,
    ( SELECT count(*) AS count
           FROM structures s
          WHERE s.pah::text = h.pah::text) AS structures_count,
    ( SELECT count(*) AS count
           FROM structures s
          WHERE s.pah::text = h.pah::text AND s.structure_class::text = 'Primary Structure'::text) AS primary_structures_count,
    ( SELECT count(*) AS count
           FROM structures s
          WHERE s.pah::text = h.pah::text AND s.structure_class::text = 'Secondary Structure'::text) AS secondary_structures_count,
    ( SELECT count(*) AS count
           FROM replacement_structures rs
          WHERE rs.pah::text = h.pah::text) AS replacement_structures_count,
    ( SELECT sum(s.secondary_compensation_value) AS sum
           FROM v_structures s
          WHERE s.pah::text = h.pah::text) AS secondary_structures_compensation_value,
    ( SELECT sum(s.primary_compensation_value) AS sum
           FROM v_structures s
          WHERE s.pah::text = h.pah::text) AS primary_structures_compensation_value,
    ( SELECT sum(s.replacement_value) AS sum
           FROM v_replacement_structures s
          WHERE s.pah::text = h.pah::text) AS replacement_structures_value,
    hla.lease_cost_total,
    hla.permanent_land_area,
    hla.permanent_land_value,
    hla.land_compensation_value,
    hla.replacement_land_area,
    ( SELECT sum(ts.compensation) AS sum
           FROM v_trees_summary ts
          WHERE ts.pah::text = h.pah::text) AS trees_compensation,
    ( SELECT sum(ts.replacement_saplings) AS sum
           FROM v_trees_summary ts
          WHERE ts.pah::text = h.pah::text) AS replacement_saplings,
    ( SELECT sum(cp.crop_size) AS sum
           FROM v_crops cp
          WHERE cp.pah::text = h.pah::text) AS crop_size,
    ( SELECT sum(cp.crop_value) AS sum
           FROM v_crops cp
          WHERE cp.pah::text = h.pah::text) AS crop_value,
    (EXISTS ( SELECT true AS bool
           FROM structures s
          WHERE s.pah::text = h.pah::text AND s.protected = true)) AS has_protected,
    (EXISTS ( SELECT 1
           FROM households_survey hs
          WHERE hs.pah = h.pah::text)) AS survey_complete,
    h.duplicate_pah,
    ( SELECT sum(s.primary_value) AS sum
           FROM v_structures s
          WHERE s.pah::text = h.pah::text) AS primary_structures_value
   FROM households h
     LEFT JOIN person ph ON h.householdhead_id = ph.person_id
     LEFT JOIN person pc ON h.cosignatory_id = pc.person_id
     JOIN villages v ON h.village_id = v.village_id
     LEFT JOIN v_households_land_assets hla ON h.pah::text = hla.pah::text
     LEFT JOIN icas i ON h.pah::text = i.pah::text AND i.is_current = true;

ALTER TABLE public.v_households
    OWNER TO postgres;


commit;