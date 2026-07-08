-- 002_create_graves_table.sql
-- Creates public.graves and imports records from incoming_data/graves.csv.
--
-- One row per deceased person recorded in a household's grave(s).
-- coffin is normalised from yes/no to boolean.

BEGIN;

CREATE TABLE public.graves (
    grave_id bigint NOT NULL,
    pah character varying(9) NOT NULL REFERENCES public.households(pah),
    deceased character varying(200),
    year_of_death integer,
    age character varying(20),
    coffin boolean,
    marker character varying(50),
    relation character varying(50),
    location character varying(200),
    ica_option character varying(200)
);

ALTER TABLE public.graves ALTER COLUMN grave_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.graves_grave_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

ALTER TABLE public.graves ADD CONSTRAINT graves_pkey PRIMARY KEY (grave_id);

ALTER TABLE public.graves OWNER TO postgres;

CREATE TEMP TABLE _graves_csv (
  csv_pah         text,
  csv_deceased    text,
  csv_year        text,
  csv_age         text,
  csv_coffin      text,
  csv_marker      text,
  csv_relation    text,
  csv_location    text,
  csv_ica_option  text
) ON COMMIT DROP;

INSERT INTO _graves_csv VALUES
  ('PAH081', 'Muyolela Lifasi', '1999', 'Adult', 'yes', 'Clay', NULL, NULL, 'Cover over - Part in-kind / part cash compensation'),
  ('PAH081', 'Libali Muyendekwa', '1998', 'Adult', 'yes', 'Clay', NULL, NULL, 'Cover over - Part in-kind / part cash compensation'),
  ('PAH110', 'Monde Mumbuwa', '2021', 'Adult', 'yes', 'Clay', NULL, 'Mbowe - Mutundandobe Island', 'Unknown'),
  ('PAH110', 'Rosemary Masiliso', '2014', 'Adult', 'yes', 'Clay', NULL, 'Mbowe - Mutundandobe Island', 'Unknown'),
  ('PAH110', 'Mukitwa Musiwa', '2013', 'Adult', 'yes', 'Clay', NULL, 'Mbowe - Mutundandobe Island', 'Unknown'),
  ('PAH110', 'Machilombo Musha', '2021', 'Adult', 'yes', 'Clay', NULL, 'Mbowe - Mutundandobe Island', 'Unknown'),
  ('PAH110', 'Daugrher Munalula Sibote', '2021', 'Infant', 'no', 'Clay', NULL, NULL, 'Unknown'),
  ('PAH110', 'Namushi Mwakoi', '1999', 'Child', 'no', 'Clay', NULL, NULL, 'Unknown'),
  ('PAH110', 'Mundia Sitali', '1989', 'Adult', 'no', 'Clay', NULL, 'Mbowe - Lweti Island', 'Unknown'),
  ('PAH110', 'Masiye Mundia', '2001', 'Adult', 'no', 'Clay', NULL, 'Mbowe - Lweti Island', 'Unknown'),
  ('PAH110', 'Namukolo Mundia', '1992', 'Adult', 'no', 'Clay', NULL, 'Mbowe - Lweti Island', 'Unknown'),
  ('PAH110', 'Katekelelwa Mundia', '1994', 'Adult', 'no', 'Clay', NULL, 'Mbowe - Lweti Island', 'Unknown'),
  ('PAH111', 'Likando Mufalali', '2019', 'Adult', 'yes', 'Brick', 'Uncle', NULL, 'Silumesi Agreement'),
  ('PAH111', 'Spencer Silumesi Mufalali', '1995', 'Adult', 'yes', 'Brick', 'Parent', NULL, 'Silumesi Agreement'),
  ('PAH111', 'Makachana Lungowe', '1999', 'Adult', 'yes', 'Earth_only', 'Uncle', NULL, 'Silumesi Agreement'),
  ('PAH111', 'Muyunda Silumesi', '2001', 'Infant', 'no', 'Earth_only', 'Son_daughter', NULL, 'Silumesi Agreement'),
  ('PAH111', 'Mwimanenwa Mwimanenwa', '2015', 'Infant', 'no', 'Earth_only', 'Nephew_niece', NULL, 'Silumesi Agreement');

INSERT INTO public.graves (pah, deceased, year_of_death, age, coffin, marker, relation, location, ica_option)
SELECT
  csv_pah,
  csv_deceased,
  csv_year::integer,
  csv_age,
  (csv_coffin = 'yes'),
  csv_marker,
  csv_relation,
  csv_location,
  csv_ica_option
FROM _graves_csv;

CREATE VIEW public.v_graves
 AS
SELECT * FROM graves;

ALTER TABLE public.v_graves
    OWNER TO postgres;

ALTER TABLE IF EXISTS public.households
    ADD COLUMN confidential boolean DEFAULT false;

ALTER TABLE IF EXISTS public.households
    ADD COLUMN sdate_structures date;

ALTER TABLE IF EXISTS public.households
    ADD COLUMN sdate_landholdings date;

ALTER TABLE IF EXISTS public.households
    ADD COLUMN sdate_gardensdryland date;    


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
          WHERE s.pah::text = h.pah::text) AS primary_structures_value,
    h.confidential,
	h.sdate_structures,
	h.sdate_landholdings,
	h.sdate_gardensdryland
   FROM households h
     LEFT JOIN person ph ON h.householdhead_id = ph.person_id
     LEFT JOIN person pc ON h.cosignatory_id = pc.person_id
     JOIN villages v ON h.village_id = v.village_id
     LEFT JOIN v_households_land_assets hla ON h.pah::text = hla.pah::text
     LEFT JOIN icas i ON h.pah::text = i.pah::text AND i.is_current = true;

ALTER TABLE public.v_households
    OWNER TO postgres;
UPDATE households set sdate_gardensdryland='2022-02-18' WHERE pah='PAH001';
UPDATE households set sdate_gardensdryland='2021-11-19' WHERE pah='PAH009';
UPDATE households set sdate_gardensdryland='2021-11-19' WHERE pah='PAH011';
UPDATE households set sdate_gardensdryland='2021-11-19' WHERE pah='PAH015';
UPDATE households set sdate_gardensdryland='2021-11-19' WHERE pah='PAH016';
UPDATE households set sdate_gardensdryland='2022-02-22' WHERE pah='PAH022';
UPDATE households set sdate_gardensdryland='2022-02-22' WHERE pah='PAH028';
UPDATE households set sdate_gardensdryland='2022-02-22' WHERE pah='PAH029';
UPDATE households set sdate_gardensdryland='2021-11-24' WHERE pah='PAH030';
UPDATE households set sdate_gardensdryland='2021-11-17' WHERE pah='PAH034';
UPDATE households set sdate_gardensdryland='2021-11-17' WHERE pah='PAH036';
UPDATE households set sdate_gardensdryland='2021-11-18' WHERE pah='PAH037';
UPDATE households set sdate_gardensdryland='2021-11-18' WHERE pah='PAH038';
UPDATE households set sdate_gardensdryland='2022-02-22' WHERE pah='PAH038';
UPDATE households set sdate_gardensdryland='2022-03-09' WHERE pah='PAH044';
UPDATE households set sdate_gardensdryland='2022-02-22' WHERE pah='PAH051';
UPDATE households set sdate_gardensdryland='2021-11-17' WHERE pah='PAH054';
UPDATE households set sdate_gardensdryland='2021-11-17' WHERE pah='PAH055';
UPDATE households set sdate_gardensdryland='2021-11-17' WHERE pah='PAH056';
UPDATE households set sdate_gardensdryland='2021-11-22' WHERE pah='PAH057';
UPDATE households set sdate_gardensdryland='2021-11-22' WHERE pah='PAH058';
UPDATE households set sdate_gardensdryland='2021-11-30' WHERE pah='PAH060';
UPDATE households set sdate_gardensdryland='2022-02-28' WHERE pah='PAH063';
UPDATE households set sdate_gardensdryland='2021-11-18' WHERE pah='PAH070';
UPDATE households set sdate_gardensdryland='2021-11-18' WHERE pah='PAH073';
UPDATE households set sdate_gardensdryland='2021-11-20' WHERE pah='PAH074';
UPDATE households set sdate_gardensdryland='2021-11-20' WHERE pah='PAH075';
UPDATE households set sdate_gardensdryland='2021-11-20' WHERE pah='PAH076';
UPDATE households set sdate_gardensdryland='2021-11-20' WHERE pah='PAH077';
UPDATE households set sdate_gardensdryland='2022-02-18' WHERE pah='PAH081';
UPDATE households set sdate_gardensdryland='2022-02-18' WHERE pah='PAH082';
UPDATE households set sdate_gardensdryland='2022-02-22' WHERE pah='PAH088';
UPDATE households set sdate_gardensdryland='2021-11-24' WHERE pah='PAH089';
UPDATE households set sdate_gardensdryland='2021-11-24' WHERE pah='PAH090';
UPDATE households set sdate_gardensdryland='2021-11-24' WHERE pah='PAH091';
UPDATE households set sdate_gardensdryland='2021-11-24' WHERE pah='PAH092';
UPDATE households set sdate_gardensdryland='2021-11-24' WHERE pah='PAH097';
UPDATE households set sdate_gardensdryland='2021-11-26' WHERE pah='PAH098';
UPDATE households set sdate_gardensdryland='2021-11-24' WHERE pah='PAH104';
UPDATE households set sdate_gardensdryland='2022-02-22' WHERE pah='PAH108';
UPDATE households set sdate_gardensdryland='2022-02-22' WHERE pah='PAH112';
UPDATE households set sdate_gardensdryland='2021-11-24' WHERE pah='PAH115';
UPDATE households set sdate_gardensdryland='2022-02-28' WHERE pah='PAH137';
UPDATE households set sdate_gardensdryland='2021-11-30' WHERE pah='PAH144';
UPDATE households set sdate_gardensdryland='2021-11-30' WHERE pah='PAH150';
UPDATE households set sdate_gardensdryland='2022-02-10' WHERE pah='PAH150';
UPDATE households set sdate_gardensdryland='2021-11-29' WHERE pah='PAH152';
UPDATE households set sdate_gardensdryland='2021-11-30' WHERE pah='PAH154';
UPDATE households set sdate_gardensdryland='2021-12-02' WHERE pah='PAH180';
UPDATE households set sdate_gardensdryland='2021-11-30' WHERE pah='PAH181';
UPDATE households set sdate_gardensdryland='2022-02-22' WHERE pah='PAH181';
UPDATE households set sdate_gardensdryland='2021-11-30' WHERE pah='PAH182';
UPDATE households set sdate_gardensdryland='2021-12-03' WHERE pah='PAH183';
UPDATE households set sdate_gardensdryland='2021-12-05' WHERE pah='PAH187';
UPDATE households set sdate_gardensdryland='2021-11-30' WHERE pah='PAH188';
UPDATE households set sdate_gardensdryland='2021-11-30' WHERE pah='PAH193';
UPDATE households set sdate_gardensdryland='2021-11-30' WHERE pah='PAH194';
UPDATE households set sdate_gardensdryland='2021-12-02' WHERE pah='PAH195';
UPDATE households set sdate_gardensdryland='2021-12-03' WHERE pah='PAH200';
UPDATE households set sdate_gardensdryland='2021-11-30' WHERE pah='PAH204';
UPDATE households set sdate_gardensdryland='2021-11-30' WHERE pah='PAH205';
UPDATE households set sdate_gardensdryland='2021-12-05' WHERE pah='PAH206';
UPDATE households set sdate_gardensdryland='2021-11-30' WHERE pah='PAH211';
UPDATE households set sdate_gardensdryland='2021-12-03' WHERE pah='PAH213';
UPDATE households set sdate_gardensdryland='2021-11-30' WHERE pah='PAH230';
UPDATE households set sdate_gardensdryland='2022-02-22' WHERE pah='PAH231';
UPDATE households set sdate_gardensdryland='2021-11-29' WHERE pah='PAH232';
UPDATE households set sdate_gardensdryland='2021-11-30' WHERE pah='PAH233';
UPDATE households set sdate_gardensdryland='2021-11-30' WHERE pah='PAH242';
UPDATE households set sdate_gardensdryland='2021-11-30' WHERE pah='PAH243';
UPDATE households set sdate_gardensdryland='2022-02-22' WHERE pah='PAH246';
UPDATE households set sdate_gardensdryland='2022-02-22' WHERE pah='PAH247';
UPDATE households set sdate_gardensdryland='2022-02-22' WHERE pah='PAH250';
UPDATE households set sdate_gardensdryland='2021-11-30' WHERE pah='PAH253';
UPDATE households set sdate_gardensdryland='2022-02-18' WHERE pah='PAH253';
UPDATE households set sdate_gardensdryland='2021-11-30' WHERE pah='PAH258';
UPDATE households set sdate_gardensdryland='2021-11-30' WHERE pah='PAH268';
UPDATE households set sdate_gardensdryland='2022-02-18' WHERE pah='PAH269';
UPDATE households set sdate_gardensdryland='2021-11-29' WHERE pah='PAH271';
UPDATE households set sdate_gardensdryland='2021-11-30' WHERE pah='PAH276';
UPDATE households set sdate_gardensdryland='2021-11-30' WHERE pah='PAH277';
UPDATE households set sdate_gardensdryland='2021-12-03' WHERE pah='PAH312';
UPDATE households set sdate_gardensdryland='2021-12-04' WHERE pah='PAH313';
UPDATE households set sdate_gardensdryland='2021-12-03' WHERE pah='PAH316';
UPDATE households set sdate_gardensdryland='2021-12-03' WHERE pah='PAH318';
UPDATE households set sdate_gardensdryland='2021-12-03' WHERE pah='PAH323';
UPDATE households set sdate_gardensdryland='2021-12-05' WHERE pah='PAH327';
UPDATE households set sdate_gardensdryland='2021-12-03' WHERE pah='PAH333';
UPDATE households set sdate_gardensdryland='2021-12-05' WHERE pah='PAH342';
UPDATE households set sdate_gardensdryland='2021-12-05' WHERE pah='PAH343';
UPDATE households set sdate_gardensdryland='2021-12-02' WHERE pah='PAH344';
UPDATE households set sdate_gardensdryland='2021-12-02' WHERE pah='PAH345';
UPDATE households set sdate_gardensdryland='2021-12-04' WHERE pah='PAH352';
UPDATE households set sdate_gardensdryland='2021-12-04' WHERE pah='PAH355';
UPDATE households set sdate_gardensdryland='2021-12-05' WHERE pah='PAH357';
UPDATE households set sdate_gardensdryland='2021-12-05' WHERE pah='PAH363';
UPDATE households set sdate_gardensdryland='2021-12-09' WHERE pah='PAH372';
UPDATE households set sdate_gardensdryland='2021-12-05' WHERE pah='PAH373';
UPDATE households set sdate_gardensdryland='2022-02-22' WHERE pah='PAH375';
UPDATE households set sdate_gardensdryland='2021-12-04' WHERE pah='PAH378';
UPDATE households set sdate_gardensdryland='2021-12-04' WHERE pah='PAH379 ';
UPDATE households set sdate_gardensdryland='2021-12-05' WHERE pah='PAH380';
UPDATE households set sdate_gardensdryland='2021-12-05' WHERE pah='PAH394';
UPDATE households set sdate_gardensdryland='2022-02-18' WHERE pah='PAH400';
UPDATE households set sdate_gardensdryland='2021-12-10' WHERE pah='PAH404';
UPDATE households set sdate_gardensdryland='2022-02-22' WHERE pah='PAH430';
UPDATE households set sdate_gardensdryland='2022-02-22' WHERE pah='PAH431';
UPDATE households set sdate_gardensdryland='2022-02-22' WHERE pah='PAH432';
UPDATE households set sdate_gardensdryland='2022-02-22' WHERE pah='PAH433';
UPDATE households set sdate_gardensdryland='2022-02-28' WHERE pah='PAH434';
UPDATE households set sdate_gardensdryland='2022-02-28' WHERE pah='PAH435';
UPDATE households set sdate_gardensdryland='2022-02-18' WHERE pah='PAH437';
UPDATE households set sdate_gardensdryland='2022-02-22' WHERE pah='PAH439';
UPDATE households set sdate_gardensdryland='2021-12-05' WHERE pah='PAH440';
UPDATE households set sdate_gardensdryland='2022-02-22' WHERE pah='PAH441';
UPDATE households set sdate_gardensdryland='2022-02-18' WHERE pah='PAH443';
UPDATE households set sdate_gardensdryland='2022-03-15' WHERE pah='PAH455';
UPDATE households set sdate_gardensdryland='2022-02-18' WHERE pah='PAH458';
UPDATE households set sdate_gardensdryland='2022-02-21' WHERE pah='PAH459';
UPDATE households set sdate_gardensdryland='2022-02-18' WHERE pah='PAH604';
UPDATE households set sdate_gardensdryland='2022-02-22' WHERE pah='PAH606';
UPDATE households set sdate_gardensdryland='2022-02-28' WHERE pah='PAH610';
UPDATE households set sdate_gardensdryland='2022-02-28' WHERE pah='PAH611';
UPDATE households set sdate_gardensdryland='2022-02-28' WHERE pah='PAH612';
UPDATE households set sdate_gardensdryland='2022-02-28' WHERE pah='PAH612';
UPDATE households set sdate_gardensdryland='2022-02-28' WHERE pah='PAH621';
UPDATE households set sdate_gardensdryland='2022-02-28' WHERE pah='PAH624';
UPDATE households set sdate_gardensdryland='2022-02-28' WHERE pah='PAH625';
UPDATE households set sdate_gardensdryland='2022-02-22' WHERE pah='PAH628';
UPDATE households set sdate_gardensdryland='2022-02-22' WHERE pah='PAH630';
UPDATE households set sdate_gardensdryland='2022-02-22' WHERE pah='PAH633';
UPDATE households set sdate_gardensdryland='2022-02-22' WHERE pah='PAH634';
UPDATE households set sdate_gardensdryland='2022-02-21' WHERE pah='PAH636';
UPDATE households set sdate_gardensdryland='2022-02-22' WHERE pah='PAH644';
UPDATE households set sdate_gardensdryland='2022-03-15' WHERE pah='PAH649';
UPDATE households set sdate_gardensdryland='2022-02-22' WHERE pah='PAH681';
UPDATE households set sdate_gardensdryland='2022-02-22' WHERE pah='PAH683';
UPDATE households set sdate_gardensdryland='2022-02-22' WHERE pah='PAH684';
UPDATE households set sdate_gardensdryland='2022-02-22' WHERE pah='PAH685';
UPDATE households set sdate_gardensdryland='2022-02-22' WHERE pah='PAH686';
UPDATE households set sdate_gardensdryland='2022-02-18' WHERE pah='PAH687';
UPDATE households set sdate_gardensdryland='2022-02-22' WHERE pah='PAH688';
UPDATE households set sdate_gardensdryland='2022-02-21' WHERE pah='PAH695';
UPDATE households set sdate_gardensdryland='2022-02-21' WHERE pah='PAH696';
UPDATE households set sdate_gardensdryland='2022-02-21' WHERE pah='PAH697';
UPDATE households set sdate_gardensdryland='2022-02-10' WHERE pah='PAH698';
UPDATE households set sdate_gardensdryland='2022-02-18' WHERE pah='PAH699';
UPDATE households set sdate_structures='2021-11-19' WHERE pah='PAH001';
UPDATE households set sdate_structures='2021-11-13' WHERE pah='PAH002';
UPDATE households set sdate_structures='2021-11-13' WHERE pah='PAH003';
UPDATE households set sdate_structures='2021-11-14' WHERE pah='PAH004';
UPDATE households set sdate_structures='2021-11-14' WHERE pah='PAH005';
UPDATE households set sdate_structures='2021-11-15' WHERE pah='PAH006';
UPDATE households set sdate_structures='2021-11-15' WHERE pah='PAH007';
UPDATE households set sdate_structures='2021-11-15' WHERE pah='PAH008';
UPDATE households set sdate_structures='2021-11-16' WHERE pah='PAH009';
UPDATE households set sdate_structures='2021-11-19' WHERE pah='PAH013';
UPDATE households set sdate_structures='2021-11-19' WHERE pah='PAH014';
UPDATE households set sdate_structures='2021-11-20' WHERE pah='PAH018';
UPDATE households set sdate_structures='2021-11-16' WHERE pah='PAH021';
UPDATE households set sdate_structures='2021-11-12' WHERE pah='PAH022';
UPDATE households set sdate_structures='2021-11-16' WHERE pah='PAH023';
UPDATE households set sdate_structures='2021-11-15' WHERE pah='PAH024';
UPDATE households set sdate_structures='2021-11-16' WHERE pah='PAH025';
UPDATE households set sdate_structures='2021-11-21' WHERE pah='PAH026';
UPDATE households set sdate_structures='2021-11-21' WHERE pah='PAH028';
UPDATE households set sdate_structures='2022-02-08' WHERE pah='PAH029';
UPDATE households set sdate_structures='2021-11-15' WHERE pah='PAH033';
UPDATE households set sdate_structures='2021-11-17' WHERE pah='PAH035';
UPDATE households set sdate_structures='2021-11-15' WHERE pah='PAH039';
UPDATE households set sdate_structures='2021-11-14' WHERE pah='PAH041';
UPDATE households set sdate_structures='2021-11-13' WHERE pah='PAH043';
UPDATE households set sdate_structures='2021-11-13' WHERE pah='PAH044';
UPDATE households set sdate_structures='2021-11-14' WHERE pah='PAH046';
UPDATE households set sdate_structures='2021-11-14' WHERE pah='PAH047';
UPDATE households set sdate_structures='2021-11-15' WHERE pah='PAH048';
UPDATE households set sdate_structures='2021-11-15' WHERE pah='PAH049';
UPDATE households set sdate_structures='2021-11-16' WHERE pah='PAH050';
UPDATE households set sdate_structures='2021-11-16' WHERE pah='PAH051';
UPDATE households set sdate_structures='2021-11-16' WHERE pah='PAH052';
UPDATE households set sdate_structures='2021-11-17' WHERE pah='PAH053';
UPDATE households set sdate_structures='2021-11-18' WHERE pah='PAH059';
UPDATE households set sdate_structures='2021-11-12' WHERE pah='PAH061 ';
UPDATE households set sdate_structures='2021-11-14' WHERE pah='PAH062';
UPDATE households set sdate_structures='2021-11-15' WHERE pah='PAH063';
UPDATE households set sdate_structures='2021-11-14' WHERE pah='PAH064';
UPDATE households set sdate_structures='2021-11-15' WHERE pah='PAH065';
UPDATE households set sdate_structures='2021-11-15' WHERE pah='PAH066';
UPDATE households set sdate_structures='2021-11-15' WHERE pah='PAH067';
UPDATE households set sdate_structures='2021-11-15' WHERE pah='PAH068';
UPDATE households set sdate_structures='2021-11-18' WHERE pah='PAH069';
UPDATE households set sdate_structures='2021-11-16' WHERE pah='PAH071';
UPDATE households set sdate_structures='2021-11-16' WHERE pah='PAH072';
UPDATE households set sdate_structures='2021-11-20' WHERE pah='PAH079';
UPDATE households set sdate_structures='2021-11-20' WHERE pah='PAH080';
UPDATE households set sdate_structures='2021-11-30' WHERE pah='PAH081';
UPDATE households set sdate_structures='2021-11-15' WHERE pah='PAH082';
UPDATE households set sdate_structures='2021-11-13' WHERE pah='PAH083';
UPDATE households set sdate_structures='2021-11-14' WHERE pah='PAH084';
UPDATE households set sdate_structures='2021-11-14' WHERE pah='PAH085';
UPDATE households set sdate_structures='2021-11-14' WHERE pah='PAH086';
UPDATE households set sdate_structures='2021-11-15' WHERE pah='PAH087';
UPDATE households set sdate_structures='2021-11-24' WHERE pah='PAH088';
UPDATE households set sdate_structures='2021-11-24' WHERE pah='PAH093';
UPDATE households set sdate_structures='2021-11-20' WHERE pah='PAH094';
UPDATE households set sdate_structures='2021-11-16' WHERE pah='PAH099';
UPDATE households set sdate_structures='2021-11-20' WHERE pah='PAH100';
UPDATE households set sdate_structures='2021-11-22' WHERE pah='PAH101';
UPDATE households set sdate_structures='2021-11-22' WHERE pah='PAH102';
UPDATE households set sdate_structures='2021-11-24' WHERE pah='PAH103';
UPDATE households set sdate_structures='2021-11-29' WHERE pah='PAH108';
UPDATE households set sdate_structures='2021-11-20' WHERE pah='PAH109';
UPDATE households set sdate_structures='2021-11-23' WHERE pah='PAH110';
UPDATE households set sdate_structures='2021-11-22' WHERE pah='PAH111';
UPDATE households set sdate_structures='2021-11-22' WHERE pah='PAH112';
UPDATE households set sdate_structures='2021-11-24' WHERE pah='PAH113';
UPDATE households set sdate_structures='2021-11-22' WHERE pah='PAH114';
UPDATE households set sdate_structures='2021-11-22' WHERE pah='PAH115';
UPDATE households set sdate_structures='2021-11-24' WHERE pah='PAH130';
UPDATE households set sdate_structures='2021-11-22' WHERE pah='PAH132';
UPDATE households set sdate_structures='2021-11-24' WHERE pah='PAH133';
UPDATE households set sdate_structures='2021-11-26' WHERE pah='PAH137';
UPDATE households set sdate_structures='2021-11-22' WHERE pah='PAH143';
UPDATE households set sdate_structures='2021-11-29' WHERE pah='PAH246';
UPDATE households set sdate_structures='2022-02-17' WHERE pah='PAH375';
UPDATE households set sdate_structures='2021-12-05' WHERE pah='PAH416';
UPDATE households set sdate_structures='2021-12-06' WHERE pah='PAH417';
UPDATE households set sdate_structures='2021-12-06' WHERE pah='PAH418';
UPDATE households set sdate_structures='2022-02-08' WHERE pah='PAH436';
UPDATE households set sdate_structures='2022-02-08' WHERE pah='PAH438';
UPDATE households set sdate_structures='2021-12-05' WHERE pah='PAH445';
UPDATE households set sdate_structures='2021-12-05' WHERE pah='PAH454';
UPDATE households set sdate_structures='2022-02-17' WHERE pah='PAH455';
UPDATE households set sdate_structures='2021-12-06' WHERE pah='PAH457';
UPDATE households set sdate_structures='2022-02-08' WHERE pah='PAH458';
UPDATE households set sdate_structures='2022-02-18' WHERE pah='PAH685';
UPDATE households set sdate_landholdings='2022-02-28' WHERE pah='A None';
UPDATE households set sdate_landholdings='2022-02-20' WHERE pah='PAH001';
UPDATE households set sdate_landholdings='2022-02-15' WHERE pah='PAH027';
UPDATE households set sdate_landholdings='2022-02-08' WHERE pah='PAH029';
UPDATE households set sdate_landholdings='2021-11-25' WHERE pah='PAH040';
UPDATE households set sdate_landholdings='2021-11-30' WHERE pah='PAH047';
UPDATE households set sdate_landholdings='2022-02-19' WHERE pah='PAH055';
UPDATE households set sdate_landholdings='2021-11-26' WHERE pah='PAH082';
UPDATE households set sdate_landholdings='2022-02-09' WHERE pah='PAH082';
UPDATE households set sdate_landholdings='2022-02-19' WHERE pah='PAH097';
UPDATE households set sdate_landholdings='2021-12-03' WHERE pah='PAH105';
UPDATE households set sdate_landholdings='2021-12-04' WHERE pah='PAH105';
UPDATE households set sdate_landholdings='2022-02-17' WHERE pah='PAH106';
UPDATE households set sdate_landholdings='2021-11-28' WHERE pah='PAH107';
UPDATE households set sdate_landholdings='2021-11-28' WHERE pah='PAH108';
UPDATE households set sdate_landholdings='2021-11-28' WHERE pah='PAH108';
UPDATE households set sdate_landholdings='2021-11-28' WHERE pah='PAH108';
UPDATE households set sdate_landholdings='2022-02-12' WHERE pah='PAH116';
UPDATE households set sdate_landholdings='2021-11-24' WHERE pah='PAH117';
UPDATE households set sdate_landholdings='2021-11-24' WHERE pah='PAH118';
UPDATE households set sdate_landholdings='2021-11-24' WHERE pah='PAH121';
UPDATE households set sdate_landholdings='2021-11-25' WHERE pah='PAH122';
UPDATE households set sdate_landholdings='2021-11-25' WHERE pah='PAH123';
UPDATE households set sdate_landholdings='2021-11-25' WHERE pah='PAH124';
UPDATE households set sdate_landholdings='2021-11-24' WHERE pah='PAH125';
UPDATE households set sdate_landholdings='2021-11-24' WHERE pah='PAH126';
UPDATE households set sdate_landholdings='2021-11-25' WHERE pah='PAH127';
UPDATE households set sdate_landholdings='2021-11-26' WHERE pah='PAH128';
UPDATE households set sdate_landholdings='2021-11-25' WHERE pah='PAH129';
UPDATE households set sdate_landholdings='2021-11-25' WHERE pah='PAH130';
UPDATE households set sdate_landholdings='2021-11-24' WHERE pah='PAH134';
UPDATE households set sdate_landholdings='2021-11-24' WHERE pah='PAH135';
UPDATE households set sdate_landholdings='2021-11-25' WHERE pah='PAH136';
UPDATE households set sdate_landholdings='2021-11-25' WHERE pah='PAH139';
UPDATE households set sdate_landholdings='2021-11-28' WHERE pah='PAH140';
UPDATE households set sdate_landholdings='2021-11-24' WHERE pah='PAH141';
UPDATE households set sdate_landholdings='2021-11-26' WHERE pah='PAH142';
UPDATE households set sdate_landholdings='2021-11-30' WHERE pah='PAH145';
UPDATE households set sdate_landholdings='2021-11-30' WHERE pah='PAH146';
UPDATE households set sdate_landholdings='2021-11-30' WHERE pah='PAH147';
UPDATE households set sdate_landholdings='2022-02-12' WHERE pah='PAH148';
UPDATE households set sdate_landholdings='2021-11-30' WHERE pah='PAH149';
UPDATE households set sdate_landholdings='2021-11-25' WHERE pah='PAH150';
UPDATE households set sdate_landholdings='2022-02-09' WHERE pah='PAH150';
UPDATE households set sdate_landholdings='2022-02-16' WHERE pah='PAH150';
UPDATE households set sdate_landholdings='2021-11-30' WHERE pah='PAH151';
UPDATE households set sdate_landholdings='2021-12-02' WHERE pah='PAH151';
UPDATE households set sdate_landholdings='2022-02-16' WHERE pah='PAH153';
UPDATE households set sdate_landholdings='2021-11-27' WHERE pah='PAH167';
UPDATE households set sdate_landholdings='2021-11-24' WHERE pah='PAH168';
UPDATE households set sdate_landholdings='2021-11-24' WHERE pah='PAH169';
UPDATE households set sdate_landholdings='2021-11-24' WHERE pah='PAH170';
UPDATE households set sdate_landholdings='2021-11-24' WHERE pah='PAH175';
UPDATE households set sdate_landholdings='2021-11-24' WHERE pah='PAH177';
UPDATE households set sdate_landholdings='2021-11-30' WHERE pah='PAH179';
UPDATE households set sdate_landholdings='2021-11-24' WHERE pah='PAH180';
UPDATE households set sdate_landholdings='2022-02-10' WHERE pah='PAH181';
UPDATE households set sdate_landholdings='2022-02-13' WHERE pah='PAH181';
UPDATE households set sdate_landholdings='2022-02-13' WHERE pah='PAH181';
UPDATE households set sdate_landholdings='2021-11-29' WHERE pah='PAH182';
UPDATE households set sdate_landholdings='2021-12-03' WHERE pah='PAH184';
UPDATE households set sdate_landholdings='2021-11-30' WHERE pah='PAH190';
UPDATE households set sdate_landholdings='2021-11-30' WHERE pah='PAH191';
UPDATE households set sdate_landholdings='2021-11-30' WHERE pah='PAH192';
UPDATE households set sdate_landholdings='2022-02-14' WHERE pah='PAH193';
UPDATE households set sdate_landholdings='2021-11-30' WHERE pah='PAH194';
UPDATE households set sdate_landholdings='2021-11-29' WHERE pah='PAH195';
UPDATE households set sdate_landholdings='2021-11-30' WHERE pah='PAH196';
UPDATE households set sdate_landholdings='2021-11-30' WHERE pah='PAH198';
UPDATE households set sdate_landholdings='2021-11-30' WHERE pah='PAH198';
UPDATE households set sdate_landholdings='2021-12-01' WHERE pah='PAH199';
UPDATE households set sdate_landholdings='2021-12-02' WHERE pah='PAH199';
UPDATE households set sdate_landholdings='2021-12-02' WHERE pah='PAH201';
UPDATE households set sdate_landholdings='2021-12-03' WHERE pah='PAH202';
UPDATE households set sdate_landholdings='2021-12-03' WHERE pah='PAH203';
UPDATE households set sdate_landholdings='2021-11-29' WHERE pah='PAH204';
UPDATE households set sdate_landholdings='2021-11-30' WHERE pah='PAH206';
UPDATE households set sdate_landholdings='2021-11-29' WHERE pah='PAH207';
UPDATE households set sdate_landholdings='2021-11-30' WHERE pah='PAH208';
UPDATE households set sdate_landholdings='2021-11-30' WHERE pah='PAH209';
UPDATE households set sdate_landholdings='2021-11-30' WHERE pah='PAH210';
UPDATE households set sdate_landholdings='2021-11-30' WHERE pah='PAH215';
UPDATE households set sdate_landholdings='2021-11-27' WHERE pah='PAH216';
UPDATE households set sdate_landholdings='2021-11-27' WHERE pah='PAH217';
UPDATE households set sdate_landholdings='2021-11-27' WHERE pah='PAH218';
UPDATE households set sdate_landholdings='2021-11-27' WHERE pah='PAH219';
UPDATE households set sdate_landholdings='2021-11-27' WHERE pah='PAH220';
UPDATE households set sdate_landholdings='2021-11-27' WHERE pah='PAH221';
UPDATE households set sdate_landholdings='2021-11-27' WHERE pah='PAH222';
UPDATE households set sdate_landholdings='2021-11-27' WHERE pah='PAH223';
UPDATE households set sdate_landholdings='2021-11-27' WHERE pah='PAH224';
UPDATE households set sdate_landholdings='2021-11-27' WHERE pah='PAH225';
UPDATE households set sdate_landholdings='2021-11-28' WHERE pah='PAH226';
UPDATE households set sdate_landholdings='2021-11-24' WHERE pah='PAH227';
UPDATE households set sdate_landholdings='2021-11-24' WHERE pah='PAH228';
UPDATE households set sdate_landholdings='2021-11-24' WHERE pah='PAH229';
UPDATE households set sdate_landholdings='2021-11-24' WHERE pah='PAH231';
UPDATE households set sdate_landholdings='2022-02-09' WHERE pah='PAH231';
UPDATE households set sdate_landholdings='2021-11-29' WHERE pah='PAH233';
UPDATE households set sdate_landholdings='2021-11-29' WHERE pah='PAH233';
UPDATE households set sdate_landholdings='2021-12-01' WHERE pah='PAH234';
UPDATE households set sdate_landholdings='2021-12-01' WHERE pah='PAH235';
UPDATE households set sdate_landholdings='2021-11-29' WHERE pah='PAH236';
UPDATE households set sdate_landholdings='2022-02-10' WHERE pah='PAH236';
UPDATE households set sdate_landholdings='2021-11-29' WHERE pah='PAH237';
UPDATE households set sdate_landholdings='2021-11-29' WHERE pah='PAH239';
UPDATE households set sdate_landholdings='2021-11-29' WHERE pah='PAH240';
UPDATE households set sdate_landholdings='2021-11-29' WHERE pah='PAH241';
UPDATE households set sdate_landholdings='2021-11-30' WHERE pah='PAH244';
UPDATE households set sdate_landholdings='2021-11-29' WHERE pah='PAH245';
UPDATE households set sdate_landholdings='2021-11-28' WHERE pah='PAH247';
UPDATE households set sdate_landholdings='2022-02-09' WHERE pah='PAH247';
UPDATE households set sdate_landholdings='2021-11-28' WHERE pah='PAH248';
UPDATE households set sdate_landholdings='2021-11-24' WHERE pah='PAH249';
UPDATE households set sdate_landholdings='2021-11-24' WHERE pah='PAH250';
UPDATE households set sdate_landholdings='2021-11-28' WHERE pah='PAH254';
UPDATE households set sdate_landholdings='2021-11-25' WHERE pah='PAH255';
UPDATE households set sdate_landholdings='2021-11-29' WHERE pah='PAH256';
UPDATE households set sdate_landholdings='2021-11-25' WHERE pah='PAH257';
UPDATE households set sdate_landholdings='2021-12-05' WHERE pah='PAH259';
UPDATE households set sdate_landholdings='2021-11-25' WHERE pah='PAH260';
UPDATE households set sdate_landholdings='2021-11-27' WHERE pah='PAH261';
UPDATE households set sdate_landholdings='2021-11-27' WHERE pah='PAH262';
UPDATE households set sdate_landholdings='2021-11-25' WHERE pah='PAH263';
UPDATE households set sdate_landholdings='2021-11-24' WHERE pah='PAH264';
UPDATE households set sdate_landholdings='2021-11-24' WHERE pah='PAH265';
UPDATE households set sdate_landholdings='2021-11-24' WHERE pah='PAH266';
UPDATE households set sdate_landholdings='2021-11-24' WHERE pah='PAH267';
UPDATE households set sdate_landholdings='2021-11-25' WHERE pah='PAH269';
UPDATE households set sdate_landholdings='2021-11-28' WHERE pah='PAH271';
UPDATE households set sdate_landholdings='2022-02-09' WHERE pah='PAH271';
UPDATE households set sdate_landholdings='2021-11-28' WHERE pah='PAH272';
UPDATE households set sdate_landholdings='2021-11-28' WHERE pah='PAH273';
UPDATE households set sdate_landholdings='2022-02-14' WHERE pah='PAH273';
UPDATE households set sdate_landholdings='2021-11-28' WHERE pah='PAH274';
UPDATE households set sdate_landholdings='2021-11-28' WHERE pah='PAH275';
UPDATE households set sdate_landholdings='2022-02-14' WHERE pah='PAH275';
UPDATE households set sdate_landholdings='2021-11-28' WHERE pah='PAH277';
UPDATE households set sdate_landholdings='2022-02-13' WHERE pah='PAH278';
UPDATE households set sdate_landholdings='2022-02-14' WHERE pah='PAH278';
UPDATE households set sdate_landholdings='2021-11-28' WHERE pah='PAH279';
UPDATE households set sdate_landholdings='2021-11-26' WHERE pah='PAH280';
UPDATE households set sdate_landholdings='2021-11-26' WHERE pah='PAH281';
UPDATE households set sdate_landholdings='2021-11-26' WHERE pah='PAH282';
UPDATE households set sdate_landholdings='2021-11-26' WHERE pah='PAH290';
UPDATE households set sdate_landholdings='2021-11-26' WHERE pah='PAH291';
UPDATE households set sdate_landholdings='2021-11-26' WHERE pah='PAH293';
UPDATE households set sdate_landholdings='2021-11-27' WHERE pah='PAH295';
UPDATE households set sdate_landholdings='2021-11-27' WHERE pah='PAH296';
UPDATE households set sdate_landholdings='2021-11-27' WHERE pah='PAH300';
UPDATE households set sdate_landholdings='2021-12-02' WHERE pah='PAH301';
UPDATE households set sdate_landholdings='2021-12-02' WHERE pah='PAH302';
UPDATE households set sdate_landholdings='2021-12-02' WHERE pah='PAH303';
UPDATE households set sdate_landholdings='2021-11-24' WHERE pah='PAH304';
UPDATE households set sdate_landholdings='2021-12-01' WHERE pah='PAH305';
UPDATE households set sdate_landholdings='2021-12-01' WHERE pah='PAH306';
UPDATE households set sdate_landholdings='2021-12-02' WHERE pah='PAH308';
UPDATE households set sdate_landholdings='2021-12-01' WHERE pah='PAH309';
UPDATE households set sdate_landholdings='2021-12-01' WHERE pah='PAH310';
UPDATE households set sdate_landholdings='2021-12-01' WHERE pah='PAH311';
UPDATE households set sdate_landholdings='2021-12-02' WHERE pah='PAH312';
UPDATE households set sdate_landholdings='2021-12-02' WHERE pah='PAH313';
UPDATE households set sdate_landholdings='2021-12-02' WHERE pah='PAH314';
UPDATE households set sdate_landholdings='2021-12-02' WHERE pah='PAH315';
UPDATE households set sdate_landholdings='2021-12-02' WHERE pah='PAH317';
UPDATE households set sdate_landholdings='2021-12-02' WHERE pah='PAH317';
UPDATE households set sdate_landholdings='2021-12-02' WHERE pah='PAH319';
UPDATE households set sdate_landholdings='2021-12-02' WHERE pah='PAH320';
UPDATE households set sdate_landholdings='2021-12-02' WHERE pah='PAH321';
UPDATE households set sdate_landholdings='2021-12-02' WHERE pah='PAH321';
UPDATE households set sdate_landholdings='2021-12-02' WHERE pah='PAH322';
UPDATE households set sdate_landholdings='2021-12-02' WHERE pah='PAH322';
UPDATE households set sdate_landholdings='2021-12-02' WHERE pah='PAH324';
UPDATE households set sdate_landholdings='2021-12-01' WHERE pah='PAH325';
UPDATE households set sdate_landholdings='2021-12-01' WHERE pah='PAH326';
UPDATE households set sdate_landholdings='2021-12-02' WHERE pah='PAH326';
UPDATE households set sdate_landholdings='2021-12-02' WHERE pah='PAH328';
UPDATE households set sdate_landholdings='2021-12-01' WHERE pah='PAH329';
UPDATE households set sdate_landholdings='2021-12-01' WHERE pah='PAH330';
UPDATE households set sdate_landholdings='2021-12-02' WHERE pah='PAH331';
UPDATE households set sdate_landholdings='2021-12-02' WHERE pah='PAH331';
UPDATE households set sdate_landholdings='2021-12-01' WHERE pah='PAH332';
UPDATE households set sdate_landholdings='2021-12-01' WHERE pah='PAH334';
UPDATE households set sdate_landholdings='2021-12-02' WHERE pah='PAH334';
UPDATE households set sdate_landholdings='2021-12-02' WHERE pah='PAH336';
UPDATE households set sdate_landholdings='2021-12-02' WHERE pah='PAH337';
UPDATE households set sdate_landholdings='2021-12-02' WHERE pah='PAH338';
UPDATE households set sdate_landholdings='2021-12-02' WHERE pah='PAH339';
UPDATE households set sdate_landholdings='2021-12-01' WHERE pah='PAH340';
UPDATE households set sdate_landholdings='2021-12-02' WHERE pah='PAH341';
UPDATE households set sdate_landholdings='2021-12-03' WHERE pah='PAH342';
UPDATE households set sdate_landholdings='2021-12-01' WHERE pah='PAH345';
UPDATE households set sdate_landholdings='2021-12-02' WHERE pah='PAH346';
UPDATE households set sdate_landholdings='2021-12-01' WHERE pah='PAH347';
UPDATE households set sdate_landholdings='2021-12-02' WHERE pah='PAH348';
UPDATE households set sdate_landholdings='2021-12-02' WHERE pah='PAH349';
UPDATE households set sdate_landholdings='2021-12-02' WHERE pah='PAH350';
UPDATE households set sdate_landholdings='2021-12-03' WHERE pah='PAH351';
UPDATE households set sdate_landholdings='2021-12-03' WHERE pah='PAH353';
UPDATE households set sdate_landholdings='2021-12-03' WHERE pah='PAH354';
UPDATE households set sdate_landholdings='2021-12-03' WHERE pah='PAH355';
UPDATE households set sdate_landholdings='2021-12-03' WHERE pah='PAH356';
UPDATE households set sdate_landholdings='2021-12-04' WHERE pah='PAH358';
UPDATE households set sdate_landholdings='2022-02-17' WHERE pah='PAH359';
UPDATE households set sdate_landholdings='2021-12-04' WHERE pah='PAH360';
UPDATE households set sdate_landholdings='2021-12-03' WHERE pah='PAH361';
UPDATE households set sdate_landholdings='2021-12-03' WHERE pah='PAH362';
UPDATE households set sdate_landholdings='2021-12-03' WHERE pah='PAH365';
UPDATE households set sdate_landholdings='2021-12-03' WHERE pah='PAH366';
UPDATE households set sdate_landholdings='2021-12-03' WHERE pah='PAH367';
UPDATE households set sdate_landholdings='2021-12-03' WHERE pah='PAH368';
UPDATE households set sdate_landholdings='2021-12-03' WHERE pah='PAH370';
UPDATE households set sdate_landholdings='2021-12-03' WHERE pah='PAH371';
UPDATE households set sdate_landholdings='2021-12-04' WHERE pah='PAH372';
UPDATE households set sdate_landholdings='2021-12-04' WHERE pah='PAH374';
UPDATE households set sdate_landholdings='2021-12-03' WHERE pah='PAH376';
UPDATE households set sdate_landholdings='2021-12-03' WHERE pah='PAH377';
UPDATE households set sdate_landholdings='2021-12-03' WHERE pah='PAH381';
UPDATE households set sdate_landholdings='2021-12-04' WHERE pah='PAH382';
UPDATE households set sdate_landholdings='2021-12-04' WHERE pah='PAH383';
UPDATE households set sdate_landholdings='2021-12-04' WHERE pah='PAH384';
UPDATE households set sdate_landholdings='2021-12-03' WHERE pah='PAH385';
UPDATE households set sdate_landholdings='2021-12-03' WHERE pah='PAH386';
UPDATE households set sdate_landholdings='2021-12-04' WHERE pah='PAH386';
UPDATE households set sdate_landholdings='2021-12-03' WHERE pah='PAH387';
UPDATE households set sdate_landholdings='2021-12-03' WHERE pah='PAH388';
UPDATE households set sdate_landholdings='2021-12-03' WHERE pah='PAH390';
UPDATE households set sdate_landholdings='2021-12-03' WHERE pah='PAH391';
UPDATE households set sdate_landholdings='2021-12-03' WHERE pah='PAH392';
UPDATE households set sdate_landholdings='2021-12-04' WHERE pah='PAH396';
UPDATE households set sdate_landholdings='2021-12-04' WHERE pah='PAH397';
UPDATE households set sdate_landholdings='2021-12-04' WHERE pah='PAH397';
UPDATE households set sdate_landholdings='2021-12-04' WHERE pah='PAH398';
UPDATE households set sdate_landholdings='2021-12-04' WHERE pah='PAH399';
UPDATE households set sdate_landholdings='2022-02-10' WHERE pah='PAH400';
UPDATE households set sdate_landholdings='2022-02-10' WHERE pah='PAH400';
UPDATE households set sdate_landholdings='2022-02-12' WHERE pah='PAH402';
UPDATE households set sdate_landholdings='2021-12-04' WHERE pah='PAH403';
UPDATE households set sdate_landholdings='2021-12-04' WHERE pah='PAH405';
UPDATE households set sdate_landholdings='2021-12-04' WHERE pah='PAH405';
UPDATE households set sdate_landholdings='2021-12-04' WHERE pah='PAH405';
UPDATE households set sdate_landholdings='2021-12-04' WHERE pah='PAH406';
UPDATE households set sdate_landholdings='2022-02-12' WHERE pah='PAH406';
UPDATE households set sdate_landholdings='2021-12-04' WHERE pah='PAH407';
UPDATE households set sdate_landholdings='2021-12-04' WHERE pah='PAH408';
UPDATE households set sdate_landholdings='2021-12-04' WHERE pah='PAH409';
UPDATE households set sdate_landholdings='2021-12-04' WHERE pah='PAH410';
UPDATE households set sdate_landholdings='2021-12-04' WHERE pah='PAH411';
UPDATE households set sdate_landholdings='2021-12-04' WHERE pah='PAH412';
UPDATE households set sdate_landholdings='2021-12-04' WHERE pah='PAH413';
UPDATE households set sdate_landholdings='2021-12-04' WHERE pah='PAH415';
UPDATE households set sdate_landholdings='2021-12-06' WHERE pah='PAH419';
UPDATE households set sdate_landholdings='2022-02-09' WHERE pah='PAH420';
UPDATE households set sdate_landholdings='2022-02-08' WHERE pah='PAH421';
UPDATE households set sdate_landholdings='2022-02-08' WHERE pah='PAH422';
UPDATE households set sdate_landholdings='2021-12-04' WHERE pah='PAH423';
UPDATE households set sdate_landholdings='2021-12-04' WHERE pah='PAH424';
UPDATE households set sdate_landholdings='2021-12-04' WHERE pah='PAH429';
UPDATE households set sdate_landholdings='2022-02-10' WHERE pah='PAH430';
UPDATE households set sdate_landholdings='2022-02-11' WHERE pah='PAH431';
UPDATE households set sdate_landholdings='2022-02-08' WHERE pah='PAH436';
UPDATE households set sdate_landholdings='2022-02-08' WHERE pah='PAH438';
UPDATE households set sdate_landholdings='2021-12-04' WHERE pah='PAH440';
UPDATE households set sdate_landholdings='2022-02-09' WHERE pah='PAH441';
UPDATE households set sdate_landholdings='2022-02-09' WHERE pah='PAH442';
UPDATE households set sdate_landholdings='2022-02-09' WHERE pah='PAH442';
UPDATE households set sdate_landholdings='2022-02-09' WHERE pah='PAH443';
UPDATE households set sdate_landholdings='2021-12-04' WHERE pah='PAH444';
UPDATE households set sdate_landholdings='2022-02-11' WHERE pah='PAH444';
UPDATE households set sdate_landholdings='2022-02-09' WHERE pah='PAH453';
UPDATE households set sdate_landholdings='2022-02-09' WHERE pah='PAH456';
UPDATE households set sdate_landholdings='2022-02-09' WHERE pah='PAH456';
UPDATE households set sdate_landholdings='2022-02-08' WHERE pah='PAH458';
UPDATE households set sdate_landholdings='2022-02-15' WHERE pah='PAH458';
UPDATE households set sdate_landholdings='2022-02-08' WHERE pah='PAH460';
UPDATE households set sdate_landholdings='2022-02-12' WHERE pah='PAH600';
UPDATE households set sdate_landholdings='2022-02-16' WHERE pah='PAH601';
UPDATE households set sdate_landholdings='2022-02-13' WHERE pah='PAH603';
UPDATE households set sdate_landholdings='2022-02-14' WHERE pah='PAH605';
UPDATE households set sdate_landholdings='2022-02-13' WHERE pah='PAH607';
UPDATE households set sdate_landholdings='2022-02-17' WHERE pah='PAH619';
UPDATE households set sdate_landholdings='2022-02-20' WHERE pah='PAH621';
UPDATE households set sdate_landholdings='2022-02-13' WHERE pah='PAH627';
UPDATE households set sdate_landholdings='2022-02-16' WHERE pah='PAH627';
UPDATE households set sdate_landholdings='2022-02-17' WHERE pah='PAH628';
UPDATE households set sdate_landholdings='2022-02-16' WHERE pah='PAH629';
UPDATE households set sdate_landholdings='2022-02-14' WHERE pah='PAH630';
UPDATE households set sdate_landholdings='2022-02-18' WHERE pah='PAH630';
UPDATE households set sdate_landholdings='2022-02-16' WHERE pah='PAH631';
UPDATE households set sdate_landholdings='2022-02-14' WHERE pah='PAH632';
UPDATE households set sdate_landholdings='2022-02-18' WHERE pah='PAH640';
UPDATE households set sdate_landholdings='2022-02-16' WHERE pah='PAH643';
UPDATE households set sdate_landholdings='2022-02-14' WHERE pah='PAH649';
UPDATE households set sdate_landholdings='2022-02-14' WHERE pah='PAH649';
UPDATE households set sdate_landholdings='2022-02-15' WHERE pah='PAH682';
UPDATE households set sdate_landholdings='2022-02-11' WHERE pah='PAH685';
UPDATE households set sdate_landholdings='2022-02-11' WHERE pah='PAH687';
UPDATE households set sdate_landholdings='2022-02-11' WHERE pah='PAH688';
UPDATE households set sdate_landholdings='2022-02-11' WHERE pah='PAH694';
UPDATE households set sdate_landholdings='2022-02-20' WHERE pah='PAH694';
UPDATE households set sdate_landholdings='2022-02-11' WHERE pah='PAH697';
UPDATE households set sdate_landholdings='2022-02-11' WHERE pah='PAH698';
UPDATE households set sdate_landholdings='2022-02-14' WHERE pah='PAH698';
UPDATE households set sdate_landholdings='2022-02-11' WHERE pah='PAH699';
UPDATE households set sdate_landholdings='2022-02-11' WHERE pah='PAH699';


COMMIT;
