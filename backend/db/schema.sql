--
-- PostgreSQL database dump
--

-- Dumped from database version 14.18 (Ubuntu 14.18-0ubuntu0.22.04.1)
-- Dumped by pg_dump version 14.18 (Ubuntu 14.18-0ubuntu0.22.04.1)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: pg_trgm; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pg_trgm WITH SCHEMA public;


--
-- Name: EXTENSION pg_trgm; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION pg_trgm IS 'text similarity measurement and index searching based on trigrams';


--
-- Name: postgis; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS postgis WITH SCHEMA public;


--
-- Name: EXTENSION postgis; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION postgis IS 'PostGIS geometry and geography spatial types and functions';


--
-- Name: a_fishers_search(character varying, character varying, character varying, character varying, integer, boolean, boolean, character varying, character varying, boolean, boolean, boolean, boolean, boolean, boolean, boolean); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.a_fishers_search(p_name character varying DEFAULT NULL::character varying, p_nhs character varying DEFAULT NULL::character varying, p_nrc character varying DEFAULT NULL::character varying, p_type character varying DEFAULT NULL::character varying, p_survey_phase integer DEFAULT NULL::integer, p_social_survey boolean DEFAULT NULL::boolean, p_catch_survey boolean DEFAULT NULL::boolean, p_maungwe_active character varying DEFAULT NULL::character varying, p_limbelo_active character varying DEFAULT NULL::character varying, p_followup_flag boolean DEFAULT NULL::boolean, p_ica_signed boolean DEFAULT NULL::boolean, p_new_ica_required boolean DEFAULT NULL::boolean, p_has_multiple_icas boolean DEFAULT NULL::boolean, p_has_linked_household boolean DEFAULT NULL::boolean, p_has_notes boolean DEFAULT NULL::boolean, p_has_grievances boolean DEFAULT NULL::boolean) RETURNS TABLE(nhs character varying)
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
$$;


--
-- Name: a_households_search(character varying, character varying, boolean, boolean, boolean, boolean, boolean, boolean, boolean, boolean, boolean, character varying, bigint, character varying, character varying, character varying, character varying, character varying, character varying, boolean, boolean, boolean, boolean, boolean, boolean, boolean, boolean, boolean); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.a_households_search(p_household_head character varying DEFAULT NULL::character varying, p_pah character varying DEFAULT NULL::character varying, p_vulnerable boolean DEFAULT NULL::boolean, p_nonaffected boolean DEFAULT NULL::boolean, p_landholding_only boolean DEFAULT NULL::boolean, p_silumesii boolean DEFAULT NULL::boolean, p_new_ica_required boolean DEFAULT NULL::boolean, p_no_ica_required boolean DEFAULT NULL::boolean, p_icasigned boolean DEFAULT NULL::boolean, p_followup_flag boolean DEFAULT NULL::boolean, p_physically_displaced boolean DEFAULT NULL::boolean, p_nrc character varying DEFAULT NULL::character varying, p_village_id bigint DEFAULT NULL::bigint, p_icaoption_primary_structure character varying DEFAULT NULL::character varying, p_icaoption_structure_location character varying DEFAULT NULL::character varying, p_icaoption_landholding character varying DEFAULT NULL::character varying, p_icaoption_dryland character varying DEFAULT NULL::character varying, p_icaoption_garden character varying DEFAULT NULL::character varying, p_icaoption_transport character varying DEFAULT NULL::character varying, p_has_replacement_structures boolean DEFAULT NULL::boolean, p_has_replacement_land boolean DEFAULT NULL::boolean, p_has_protected boolean DEFAULT NULL::boolean, p_survey_complete boolean DEFAULT NULL::boolean, p_has_current_grievance boolean DEFAULT NULL::boolean, p_has_multiple_icas boolean DEFAULT NULL::boolean, p_has_linked_fisher boolean DEFAULT NULL::boolean, p_has_notes boolean DEFAULT NULL::boolean, p_is_duplicate boolean DEFAULT NULL::boolean) RETURNS TABLE(pah character varying, household_head_fullname text, date_signed date)
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


--
-- Name: a_parcels_search(character varying, character varying, character varying, character varying, character varying, boolean, boolean); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.a_parcels_search(p_pah character varying DEFAULT NULL::character varying, p_land_parcel_id character varying DEFAULT NULL::character varying, p_land_class character varying DEFAULT NULL::character varying, p_land_zone character varying DEFAULT NULL::character varying, p_village character varying DEFAULT NULL::character varying, p_cultivated boolean DEFAULT NULL::boolean, p_remaining_viable boolean DEFAULT NULL::boolean) RETURNS TABLE(land_parcel_id character varying, pah character varying)
    LANGUAGE plpgsql
    AS $$
BEGIN
  RETURN QUERY
  SELECT lp.land_parcel_id, lp.pah
  FROM   v_land_parcels lp
  WHERE  (p_pah IS NULL OR lp.pah ILIKE '%' || p_pah || '%')
    AND  (p_land_parcel_id IS NULL OR lp.land_parcel_id = p_land_parcel_id)
    AND  (p_land_class IS NULL OR lp.land_class = p_land_class)
    AND  (p_land_zone IS NULL OR lp.land_zone = p_land_zone)
    AND  (p_village IS NULL OR lp.village = p_village)
    AND  (p_cultivated IS NULL OR lp.cultivated = p_cultivated)
    AND  (p_remaining_viable IS NULL OR lp.remaining_viable = p_remaining_viable);
END;
$$;


--
-- Name: a_person_search(character varying, character varying, character varying, character varying, character varying, boolean, boolean, boolean, boolean, boolean, boolean, boolean); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.a_person_search(p_name character varying DEFAULT NULL::character varying, p_nrc character varying DEFAULT NULL::character varying, p_nhs character varying DEFAULT NULL::character varying, p_pah character varying DEFAULT NULL::character varying, p_gender character varying DEFAULT NULL::character varying, p_is_fisher boolean DEFAULT NULL::boolean, p_is_head boolean DEFAULT NULL::boolean, p_is_cosignatory boolean DEFAULT NULL::boolean, p_is_disabled boolean DEFAULT NULL::boolean, p_has_photo boolean DEFAULT NULL::boolean, p_is_deceased boolean DEFAULT NULL::boolean, p_has_grievances boolean DEFAULT NULL::boolean) RETURNS TABLE(person_id bigint)
    LANGUAGE plpgsql
    AS $$
BEGIN
  RETURN QUERY
  SELECT p.person_id
  FROM   v_person p
  WHERE
    (p_nrc IS NULL OR p.nrc ILIKE '%' || p_nrc || '%') AND
    (p_nhs IS NULL OR p.nhs ILIKE '%' || p_nhs || '%') AND
    (p_pah IS NULL OR p.pah ILIKE '%' || p_pah || '%') AND
    (p_gender IS NULL OR p.gender = p_gender) AND
    (p_is_fisher IS NULL OR (p.nhs IS NOT NULL) = p_is_fisher) AND
    (p_is_head IS NULL OR COALESCE(p.household_head,false) = p_is_head) AND
    (p_is_cosignatory IS NULL OR COALESCE(p.cosignatory,false) = p_is_cosignatory) AND
    (p_is_disabled IS NULL OR COALESCE(p.disabled,false) = p_is_disabled) AND
    (p_has_photo IS NULL OR (p.photo_file IS NOT NULL) = p_has_photo) AND
    (p_is_deceased IS NULL OR (p.deceased_date IS NOT NULL) = p_is_deceased) AND
    (p_has_grievances IS NULL OR (EXISTS (SELECT 1 FROM public.grievances g WHERE g.person_id = p.person_id)) = p_has_grievances) AND
    (
      p_name IS NULL OR
      SIMILARITY(p.firstname, p_name) > 0.4 OR
      SIMILARITY(p.lastname,  p_name) > 0.4
    )
  ORDER BY p.lastname, p.firstname;
END
$$;


--
-- Name: a_replacements_search(character varying, character varying, character varying, character varying, character varying, boolean, boolean, character varying, boolean); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.a_replacements_search(p_pah character varying DEFAULT NULL::character varying, p_replacement_structure_id character varying DEFAULT NULL::character varying, p_replacement_option character varying DEFAULT NULL::character varying, p_replacement_class character varying DEFAULT NULL::character varying, p_icaoption_structure_location character varying DEFAULT NULL::character varying, p_protected boolean DEFAULT NULL::boolean, p_flag_followup boolean DEFAULT NULL::boolean, p_phase character varying DEFAULT NULL::character varying, p_silumesii boolean DEFAULT NULL::boolean) RETURNS TABLE(replacement_structure_id character varying, pah character varying)
    LANGUAGE plpgsql
    AS $$
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
    AND  (p_phase IS NULL OR rs.phase = p_phase)
    AND  (p_silumesii IS NULL OR COALESCE(rs.silumesii,false) = p_silumesii);
END;
$$;


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: crop_types; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.crop_types (
    crop_type character varying(100) NOT NULL,
    rate numeric(10,3) NOT NULL
);


--
-- Name: crops; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.crops (
    pah character varying(100) NOT NULL,
    crop_type character varying(100) NOT NULL,
    field_size numeric(10,3),
    coverage numeric(5,3),
    crop_id integer NOT NULL
);


--
-- Name: crops_crop_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.crops ALTER COLUMN crop_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.crops_crop_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: fishers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.fishers (
    nhs character varying(10) NOT NULL,
    person_id bigint,
    survey_phase smallint,
    social_survey boolean,
    catch_survey boolean,
    catch_data_survey boolean,
    type character varying(20),
    maungwe_active character varying(20),
    maungwe_annual_earnings numeric(12,2),
    limbelo_active character varying(20),
    limbelo_annual_earnings numeric(12,2),
    limbelo_traps integer,
    maungwe_traps integer,
    limbelo_annual_buckets numeric(10,3),
    limbelo_days_fished numeric(8,2),
    new_ica_required boolean DEFAULT false NOT NULL,
    followup_flag boolean DEFAULT false NOT NULL,
    lr_fishfarming boolean,
    lr_goatrearing boolean
);


--
-- Name: grievances; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.grievances (
    grievance_id bigint NOT NULL,
    grievance_link character varying(500),
    is_current boolean DEFAULT true NOT NULL,
    user_id bigint,
    created_at timestamp with time zone DEFAULT now(),
    grievance_ref character varying(50),
    date_received date,
    person_id bigint NOT NULL
);


--
-- Name: grievances_grievance_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.grievances ALTER COLUMN grievance_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.grievances_grievance_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: households; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.households (
    pah character varying(9) NOT NULL,
    linked_pah character varying(500),
    landholding_only boolean,
    allowance_disturbance numeric(12,3),
    allowance_transport numeric(12,3),
    allowance_transitional numeric(12,3),
    allowance_business numeric(12,3),
    allowance_rental numeric(12,3),
    lr_agricultural boolean,
    lr_livestock boolean,
    lr_water boolean,
    lr_fisheries boolean,
    lr_reedbeds boolean,
    lr_agricultureinputs boolean,
    vulnerable boolean,
    no_ica_required boolean,
    nonaffected boolean,
    silumesii boolean,
    followup_flag boolean,
    physically_displaced boolean,
    new_ica_required boolean,
    icaoption_primary_structure character varying(100),
    icaoption_landholding character varying(100),
    icaoption_structure_location character varying(100),
    icaoption_dryland character varying(100),
    icaoption_garden character varying(100),
    icaoption_transport character varying(100),
    village_id bigint,
    householdhead_id bigint,
    cosignatory_id bigint,
    duplicate_pah character varying(20)
);


--
-- Name: households_survey; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.households_survey (
    pah text,
    survey_date timestamp without time zone,
    surveyor1 text,
    surveyor2 text,
    witness_name text,
    hh_present text,
    hh_count integer,
    respondent_lastname text,
    respondent_middlename text,
    respondent_firstname text,
    respondent_relation text,
    respondent_contact1 text,
    respondent_contact2 text,
    headperson text,
    language text,
    land_access text,
    rent_amount text,
    residence_time text,
    residence_reason text,
    no_hospital_reason text,
    families integer,
    community_support text,
    water_drinking_source text,
    water_washing_source text,
    energy_cook_source text,
    energy_light_source text,
    washing text,
    toilet text,
    waste text,
    diseases_year text,
    medicine_source text,
    births_year integer,
    infant_death_year integer,
    deaths_year integer,
    death_reason text,
    hunger_months text,
    nets text,
    nets_no_reason text,
    hiv_education text,
    hiv_education_source text,
    hiv_prevention text,
    farms_gardens_count integer,
    plantations_count integer,
    trees_non_plantation text,
    trees_total integer,
    business_activities text,
    grazing text,
    grazing_owner text,
    graves_visit text,
    graves_option text,
    graves_ceremony text,
    graves_compensation text,
    household_assets text,
    resettlement_option text,
    loss_opinion text,
    relocation_option text,
    relocation_area text,
    relocation_reason text,
    relocation_disadvantage text,
    newvillage_location text,
    newvillage_location_reason text,
    newvillage_location_disadvantages text,
    resettlement_comments text,
    other_assets_concern text,
    development_priorities text,
    members_count integer,
    members_confirmed text,
    members_list text,
    lon double precision,
    lat double precision,
    globalid text,
    survey_link text
);


--
-- Name: icas; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.icas (
    ica_id bigint NOT NULL,
    pah character varying(9),
    ica_link character varying(500),
    date_signed date,
    is_current boolean DEFAULT true NOT NULL,
    type character varying(30),
    nhs character varying(10),
    CONSTRAINT icas_entity_check CHECK (((pah IS NOT NULL) OR (nhs IS NOT NULL)))
);


--
-- Name: icas_ica_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.icas ALTER COLUMN ica_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.icas_ica_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: impact_zones; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.impact_zones (
    id integer NOT NULL,
    geom public.geometry(MultiPolygon,32734),
    zone_ref character varying(20),
    area_sqm bigint
);


--
-- Name: impact_zones_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.impact_zones_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: impact_zones_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.impact_zones_id_seq OWNED BY public.impact_zones.id;


--
-- Name: land_assets; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.land_assets (
    land_asset_id character varying(9) NOT NULL,
    land_parcel_id character varying(9) NOT NULL,
    irrigation_eligible boolean,
    rate_acquisition numeric(6,3),
    rate_lease numeric(6,3),
    lease_years bigint,
    prep_allowance numeric(12,3),
    land_value numeric(12,3),
    qaqc_note text,
    phase character varying(100),
    acquisition_class character varying(100),
    area_sqm numeric(12,3),
    compensation_option character varying(100),
    lease_cost numeric(12,3)
);


--
-- Name: land_assets_geom; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.land_assets_geom (
    id integer NOT NULL,
    geom public.geometry(MultiPolygon,32734),
    land_asset_id character varying(6),
    centroid public.geometry(Point,32734)
);


--
-- Name: land_parcels; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.land_parcels (
    land_parcel_id character varying(9) NOT NULL,
    pah character varying(9) NOT NULL,
    qaqc_note text,
    land_class character varying(100),
    qaqc_action text,
    area_sqm numeric(12,3),
    cultivated boolean,
    land_zone character varying(100),
    remaining_viable boolean
);


--
-- Name: land_parcels_geom; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.land_parcels_geom (
    id integer NOT NULL,
    geom public.geometry(MultiPolygon,32734),
    land_parcel_id character varying(254),
    centroid public.geometry(Point,32734)
);


--
-- Name: land_parcels_geom_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.land_parcels_geom_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: land_parcels_geom_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.land_parcels_geom_id_seq OWNED BY public.land_parcels_geom.id;


--
-- Name: notes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.notes (
    note_id bigint NOT NULL,
    user_id bigint NOT NULL,
    note text NOT NULL,
    created_at timestamp with time zone NOT NULL,
    pah character varying(10),
    nhs character varying(10),
    CONSTRAINT notes_entity_check CHECK (((pah IS NOT NULL) OR (nhs IS NOT NULL)))
);


--
-- Name: notes_note_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.notes ALTER COLUMN note_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.notes_note_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: person; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.person (
    person_id bigint NOT NULL,
    firstname character varying(100),
    middlename character varying(100),
    lastname character varying(100),
    contact character varying(100),
    nrc character varying(100),
    pah character varying(9),
    household_head boolean,
    cosignatory boolean,
    gender character varying(10),
    pregnant_this_year boolean,
    relationship character varying(50),
    marital_status character varying(50),
    residential_status character varying(100),
    education character varying(100),
    primary_occupation character varying(100),
    secondary_occupation character varying(100),
    primary_skill character varying(100),
    secondary_skill character varying(100),
    disabled boolean,
    disabilities character varying(255),
    contact2 character varying(100),
    district character varying(100),
    origin character varying(100),
    fisher boolean,
    year_of_birth bigint,
    village_id bigint,
    fisher_village_id bigint,
    photo_file text,
    deceased_date date,
    created_at date,
    created_user_id bigint
);


--
-- Name: person_person_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.person ALTER COLUMN person_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.person_person_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: replacement_structure_notes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.replacement_structure_notes (
    note_id bigint NOT NULL,
    replacement_structure_id character varying(9) NOT NULL,
    user_id bigint NOT NULL,
    note text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: replacement_structure_notes_note_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.replacement_structure_notes_note_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: replacement_structure_notes_note_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.replacement_structure_notes_note_id_seq OWNED BY public.replacement_structure_notes.note_id;


--
-- Name: replacement_structure_types; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.replacement_structure_types (
    replacement_class character varying(100),
    replacement_option character varying(100),
    replacement_value numeric(12,3),
    replacement_type_ref character varying(100) NOT NULL,
    replacement_cost_2024 numeric(12,2)
);


--
-- Name: replacement_structures; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.replacement_structures (
    replacement_structure_id character varying(9) NOT NULL,
    pah character varying(9) NOT NULL,
    phase character varying(100),
    structure_id character varying(9),
    flag_followup boolean,
    replacement_type_ref character varying(100) NOT NULL
);


--
-- Name: structures; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.structures (
    structure_id character varying(9) NOT NULL,
    pah character varying(9) NOT NULL,
    structure_value_adjustment numeric(6,3),
    dimensions numeric(12,3),
    rooms bigint,
    doors bigint,
    windows bigint,
    owner_tenant character varying(100),
    owner_name character varying(100),
    replacement_structure_id character varying(9),
    followup_flag boolean,
    data_notes text,
    door_value numeric(12,3),
    floor_value numeric(12,3),
    wall_value numeric(12,3),
    roof_value numeric(12,3),
    window_value numeric(12,3),
    structure_value numeric(12,3),
    land_zone character varying(100),
    structure_class character varying(100),
    structure_type character varying(100),
    secondary_description character varying(100),
    secondary_rate numeric(12,3),
    roof_type character varying(100),
    roof_rate numeric(12,3),
    walls_type character varying(100),
    walls_rate numeric(12,3),
    floor_type character varying(100),
    floor_rate numeric(12,3),
    doors_type character varying(100),
    doors_rate numeric(12,3),
    windows_type character varying(100),
    windows_rate numeric(12,3),
    replacement_type_ref character varying(100),
    protected boolean
);


--
-- Name: structures_geom; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.structures_geom (
    id integer NOT NULL,
    geom public.geometry(Point,32734),
    structure_id character varying(10)
);


--
-- Name: structures_geom_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.structures_geom_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: structures_geom_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.structures_geom_id_seq OWNED BY public.structures_geom.id;


--
-- Name: tree_types; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tree_types (
    tree_type character varying(100) NOT NULL,
    rate_juvenile numeric(10,3) NOT NULL,
    rate_adult numeric(10,3) NOT NULL,
    tree_type_id integer NOT NULL
);


--
-- Name: tree_types_tree_type_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.tree_types ALTER COLUMN tree_type_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.tree_types_tree_type_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: trees; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.trees (
    pah character varying(10) NOT NULL,
    tree_type character varying(100) NOT NULL,
    juvenile_count bigint,
    productive_count bigint,
    old_count bigint,
    adjustment numeric(10,3),
    tree_id integer NOT NULL
);


--
-- Name: trees_tree_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.trees ALTER COLUMN tree_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.trees_tree_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: user; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."user" (
    user_id bigint NOT NULL,
    email character varying NOT NULL,
    password_digest character varying,
    first_name character varying NOT NULL,
    last_name character varying NOT NULL,
    is_deleted boolean,
    can_login boolean DEFAULT true,
    organisation character varying,
    admin boolean
);


--
-- Name: user_login; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_login (
    user_id bigint NOT NULL,
    login timestamp with time zone NOT NULL
);


--
-- Name: user_pageview; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_pageview (
    user_id bigint NOT NULL,
    page character varying NOT NULL,
    viewtime timestamp with time zone NOT NULL
);


--
-- Name: user_user_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public."user" ALTER COLUMN user_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.user_user_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: usergroup; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.usergroup (
    usergroup_id bigint NOT NULL,
    usergroup_name character varying NOT NULL,
    usergroup_ref character varying NOT NULL
);


--
-- Name: usergroup_user; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.usergroup_user (
    usergroup_id bigint NOT NULL,
    user_id bigint NOT NULL
);


--
-- Name: usergroup_usergroup_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.usergroup ALTER COLUMN usergroup_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.usergroup_usergroup_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: v_crops; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.v_crops AS
 SELECT c.pah,
    c.crop_type,
    c.field_size,
    c.coverage,
    ct.rate,
    (c.field_size * c.coverage) AS crop_size,
    (((c.field_size / (10000)::numeric) * c.coverage) * ct.rate) AS crop_value
   FROM (public.crops c
     JOIN public.crop_types ct ON (((c.crop_type)::text = (ct.crop_type)::text)));


--
-- Name: v_fishers; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.v_fishers AS
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
    ((((COALESCE(f.limbelo_traps, 0) + COALESCE(f.maungwe_traps, 0)) * 2))::numeric * 12.5) AS site_compensation_calc,
    GREATEST(((((COALESCE(f.limbelo_traps, 0) + COALESCE(f.maungwe_traps, 0)) * 2))::numeric * 12.5), (500)::numeric) AS site_compensation,
        CASE
            WHEN ((f.maungwe_active)::text = 'Active'::text) THEN (COALESCE(f.maungwe_traps, 0) * 1500)
            ELSE 0
        END AS maungwe_annual_earn,
    COALESCE(f.limbelo_annual_buckets, (0)::numeric) AS limbelo_annual_earn,
    ((
        CASE
            WHEN ((f.maungwe_active)::text = 'Active'::text) THEN (COALESCE(f.maungwe_traps, 0) * 1500)
            ELSE 0
        END)::numeric + (COALESCE(f.limbelo_annual_buckets, (0)::numeric) * (332)::numeric)) AS transitional_allowance,
    ((GREATEST(((((COALESCE(f.limbelo_traps, 0) + COALESCE(f.maungwe_traps, 0)) * 2))::numeric * 12.5), (500)::numeric) + (
        CASE
            WHEN ((f.maungwe_active)::text = 'Active'::text) THEN (COALESCE(f.maungwe_traps, 0) * 1500)
            ELSE 0
        END)::numeric) + (COALESCE(f.limbelo_annual_buckets, (0)::numeric) * (332)::numeric)) AS total_compensation,
    i.date_signed,
    i.ica_link,
    f.new_ica_required,
    f.followup_flag,
    ph.pah AS linked_pah,
    f.lr_fishfarming,
    f.lr_goatrearing
   FROM ((public.fishers f
     JOIN public.person ph ON ((f.person_id = ph.person_id)))
     LEFT JOIN public.icas i ON ((((f.nhs)::text = (i.nhs)::text) AND (i.is_current = true))));


--
-- Name: villages; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.villages (
    village_id bigint NOT NULL,
    village character varying(100) NOT NULL
);


--
-- Name: v_person; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.v_person AS
 SELECT p.person_id,
    p.pah,
    f.nhs,
    p.household_head,
    p.cosignatory,
    p.village_id,
    v.village,
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
   FROM ((public.person p
     LEFT JOIN public.villages v ON ((p.village_id = v.village_id)))
     LEFT JOIN public.fishers f ON ((p.person_id = f.person_id)));


--
-- Name: v_grievances; Type: VIEW; Schema: public; Owner: -
--

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
   FROM (((public.grievances g
     LEFT JOIN public.households h ON ((g.person_id = h.householdhead_id)))
     LEFT JOIN public.fishers f ON ((g.person_id = f.person_id)))
     LEFT JOIN public.v_person vf ON ((g.person_id = vf.person_id)));


--
-- Name: v_land_assets; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.v_land_assets AS
 SELECT la.land_asset_id,
    la.land_parcel_id,
    lp.pah,
    lp.land_class,
    lp.cultivated,
    lp.land_zone,
    la.phase,
    la.compensation_option,
    la.irrigation_eligible,
    la.prep_allowance,
    la.acquisition_class,
    la.area_sqm,
    la.rate_acquisition,
    la.rate_lease,
    la.lease_years,
    la.lease_cost,
    (la.lease_cost * (la.lease_years)::numeric) AS lease_cost_total,
    la.land_value,
    la.qaqc_note,
    public.st_asgeojson(public.st_transform(lag.centroid, 4326)) AS centroid,
        CASE
            WHEN (((la.acquisition_class)::text = 'Permanent'::text) AND ((la.compensation_option)::text = '2: Land Allocation'::text)) THEN la.area_sqm
            ELSE NULL::numeric
        END AS replacement_land_area,
        CASE
            WHEN (((la.acquisition_class)::text = 'Permanent'::text) AND (((la.compensation_option)::text = '1: Self-Source'::text) OR ((la.compensation_option)::text = '3: Cash Compensation'::text))) THEN la.land_value
            ELSE NULL::numeric
        END AS compensation_value
   FROM ((public.land_assets la
     JOIN public.land_assets_geom lag ON (((la.land_asset_id)::text = (lag.land_asset_id)::text)))
     JOIN public.land_parcels lp ON (((la.land_parcel_id)::text = (lp.land_parcel_id)::text)));


--
-- Name: v_households_land_assets; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.v_households_land_assets AS
 SELECT lp.pah,
    sum(COALESCE(la.lease_cost_total, (0)::numeric)) AS lease_cost_total,
    sum(
        CASE
            WHEN ((la.acquisition_class)::text = 'Permanent'::text) THEN la.area_sqm
            ELSE NULL::numeric
        END) AS permanent_land_area,
    sum(
        CASE
            WHEN ((la.acquisition_class)::text = 'Permanent'::text) THEN la.land_value
            ELSE NULL::numeric
        END) AS permanent_land_value,
    sum(COALESCE(la.compensation_value, (0)::numeric)) AS land_compensation_value,
    sum(COALESCE(la.replacement_land_area, (0)::numeric)) AS replacement_land_area
   FROM (public.v_land_assets la
     JOIN public.land_parcels lp ON (((la.land_parcel_id)::text = (lp.land_parcel_id)::text)))
  GROUP BY lp.pah;


--
-- Name: v_replacement_structures; Type: VIEW; Schema: public; Owner: -
--

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
    rst.replacement_cost_2024,
    h.silumesii
   FROM (((public.replacement_structures rs
     JOIN public.replacement_structure_types rst ON (((rs.replacement_type_ref)::text = (rst.replacement_type_ref)::text)))
     LEFT JOIN public.households h ON (((rs.pah)::text = (h.pah)::text)))
     LEFT JOIN public.structures s ON (((rs.structure_id)::text = (s.structure_id)::text)));


--
-- Name: v_structures; Type: VIEW; Schema: public; Owner: -
--

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


--
-- Name: v_trees; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.v_trees AS
 SELECT t.pah,
    t.tree_type,
    t.juvenile_count,
    t.productive_count,
    t.old_count,
    t.adjustment,
    tt.rate_juvenile,
    tt.rate_adult,
    (tt.rate_juvenile * (t.juvenile_count)::numeric) AS juvenile_value,
    (tt.rate_adult * (t.productive_count)::numeric) AS productive_value,
    (((t.juvenile_count + t.productive_count) + t.old_count) * 2) AS replacement_saplings,
    (((((t.juvenile_count + t.productive_count) + t.old_count) * 2))::numeric * tt.rate_juvenile) AS replacement_sapling_value,
    (
        CASE
            WHEN (t.productive_count > 0) THEN ((tt.rate_adult * (t.productive_count)::numeric) + tt.rate_juvenile)
            WHEN (t.productive_count = 0) THEN (0)::numeric
            ELSE NULL::numeric
        END + COALESCE(t.adjustment, (0)::numeric)) AS compensation
   FROM (public.trees t
     JOIN public.tree_types tt ON (((t.tree_type)::text = (tt.tree_type)::text)));


--
-- Name: v_trees_summary; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.v_trees_summary AS
 SELECT t.pah,
    t.tree_type,
    sum(t.juvenile_count) AS juvenile_count,
    sum(t.productive_count) AS productive_count,
    sum(t.replacement_saplings) AS replacement_saplings,
    sum(t.compensation) AS compensation
   FROM public.v_trees t
  GROUP BY t.pah, t.tree_type;


--
-- Name: v_households; Type: VIEW; Schema: public; Owner: -
--

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
          WHERE (hs.pah = (h.pah)::text))) AS survey_complete,
    h.duplicate_pah
   FROM (((((public.households h
     LEFT JOIN public.person ph ON ((h.householdhead_id = ph.person_id)))
     LEFT JOIN public.person pc ON ((h.cosignatory_id = pc.person_id)))
     JOIN public.villages v ON ((h.village_id = v.village_id)))
     LEFT JOIN public.v_households_land_assets hla ON (((h.pah)::text = (hla.pah)::text)))
     LEFT JOIN public.icas i ON ((((h.pah)::text = (i.pah)::text) AND (i.is_current = true))));


--
-- Name: v_household_compensation; Type: VIEW; Schema: public; Owner: -
--

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


--
-- Name: v_land_assets_gis; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.v_land_assets_gis AS
 SELECT la.land_asset_id,
    lag.geom,
    la.land_parcel_id,
    lp.pah,
    lp.land_class,
    lp.cultivated,
    lp.land_zone,
    lp.area_sqm AS parcel_area_sqm,
    la.area_sqm,
    la.irrigation_eligible,
    la.phase,
    la.acquisition_class,
    la.compensation_option
   FROM ((public.land_assets la
     JOIN public.land_assets_geom lag ON (((la.land_asset_id)::text = (lag.land_asset_id)::text)))
     JOIN public.land_parcels lp ON (((la.land_parcel_id)::text = (lp.land_parcel_id)::text)));


--
-- Name: v_land_parcels; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.v_land_parcels AS
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
          WHERE (((la.land_parcel_id)::text = (lp.land_parcel_id)::text) AND ((la.acquisition_class)::text <> 'None'::text))) AS area_acquired,
    lp.remaining_viable,
    ( SELECT sum((COALESCE(la.lease_cost_total, (0)::numeric) + COALESCE(la.compensation_value, (0)::numeric))) AS sum
           FROM public.v_land_assets la
          WHERE ((la.land_parcel_id)::text = (lp.land_parcel_id)::text)) AS cash_cost_total,
    ( SELECT sum(COALESCE(la.replacement_land_area, (0)::numeric)) AS sum
           FROM public.v_land_assets la
          WHERE ((la.land_parcel_id)::text = (lp.land_parcel_id)::text)) AS replacement_land_area,
    h.householdhead_id,
    v.village
   FROM (((public.land_parcels lp
     JOIN public.land_parcels_geom lpg ON (((lp.land_parcel_id)::text = (lpg.land_parcel_id)::text)))
     JOIN public.households h ON (((lp.pah)::text = (h.pah)::text)))
     JOIN public.villages v ON ((h.village_id = v.village_id)));


--
-- Name: v_land_parcels_gis; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.v_land_parcels_gis AS
 SELECT lp.land_parcel_id,
    lpg.geom,
    lp.pah,
    lp.land_class,
    lp.cultivated,
    lp.land_zone,
    lp.area_sqm
   FROM (public.land_parcels lp
     JOIN public.land_parcels_geom lpg ON (((lp.land_parcel_id)::text = (lpg.land_parcel_id)::text)));


--
-- Name: v_notes; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.v_notes AS
 SELECT n.note_id,
    n.user_id,
    n.pah,
    n.nhs,
    n.note,
    n.created_at,
    (((u.first_name)::text || ' '::text) || (u.last_name)::text) AS created_by
   FROM (public.notes n
     LEFT JOIN public."user" u ON ((u.user_id = n.user_id)));


--
-- Name: v_replacement_structure_notes; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.v_replacement_structure_notes AS
 SELECT n.note_id,
    n.replacement_structure_id,
    n.user_id,
    n.note,
    n.created_at,
    (((u.first_name)::text || ' '::text) || (u.last_name)::text) AS created_by
   FROM (public.replacement_structure_notes n
     LEFT JOIN public."user" u ON ((u.user_id = n.user_id)));


--
-- Name: v_structures_gis; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.v_structures_gis AS
 SELECT s.structure_id,
    s.replacement_structure_id,
    sg.geom,
    s.pah,
    s.rooms,
    s.dimensions,
    s.followup_flag,
    s.land_zone,
    s.structure_class,
    s.structure_type,
    s.secondary_description
   FROM (public.structures s
     JOIN public.structures_geom sg ON (((s.structure_id)::text = (sg.structure_id)::text)));


--
-- Name: v_user; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.v_user AS
 SELECT u.user_id,
    concat(u.first_name, ' ', u.last_name) AS user_name,
    u.first_name,
    u.last_name,
    u.email,
    u.is_deleted,
    u.can_login,
    u.admin,
    u.organisation,
    ( SELECT count(*) AS count
           FROM public.user_pageview pv
          WHERE (pv.user_id = u.user_id)) AS pageview_count
   FROM public."user" u;


--
-- Name: v_usergroup_user; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.v_usergroup_user AS
 SELECT ugu.user_id,
    ug.usergroup_name,
    ug.usergroup_ref
   FROM (public.usergroup_user ugu
     JOIN public.usergroup ug ON ((ugu.usergroup_id = ug.usergroup_id)));


--
-- Name: villages_village_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.villages ALTER COLUMN village_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.villages_village_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: zones; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.zones (
    id numeric NOT NULL,
    geom public.geometry(MultiPolygon,32734),
    name character varying(80),
    color character varying(10),
    bank character varying(12)
);


--
-- Name: impact_zones id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.impact_zones ALTER COLUMN id SET DEFAULT nextval('public.impact_zones_id_seq'::regclass);


--
-- Name: land_parcels_geom id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.land_parcels_geom ALTER COLUMN id SET DEFAULT nextval('public.land_parcels_geom_id_seq'::regclass);


--
-- Name: replacement_structure_notes note_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.replacement_structure_notes ALTER COLUMN note_id SET DEFAULT nextval('public.replacement_structure_notes_note_id_seq'::regclass);


--
-- Name: structures_geom id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.structures_geom ALTER COLUMN id SET DEFAULT nextval('public.structures_geom_id_seq'::regclass);


--
-- Name: crop_types crop_types_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.crop_types
    ADD CONSTRAINT crop_types_pkey PRIMARY KEY (crop_type, rate);


--
-- Name: crops crops_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.crops
    ADD CONSTRAINT crops_pkey PRIMARY KEY (crop_id);


--
-- Name: fishers fishers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.fishers
    ADD CONSTRAINT fishers_pkey PRIMARY KEY (nhs);


--
-- Name: grievances grievances_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.grievances
    ADD CONSTRAINT grievances_pkey PRIMARY KEY (grievance_id);


--
-- Name: households households_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.households
    ADD CONSTRAINT households_pkey PRIMARY KEY (pah);


--
-- Name: icas icas_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.icas
    ADD CONSTRAINT icas_pkey PRIMARY KEY (ica_id);


--
-- Name: impact_zones impact_zones_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.impact_zones
    ADD CONSTRAINT impact_zones_pkey PRIMARY KEY (id);


--
-- Name: land_assets_geom land_assets_geom_pkey1; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.land_assets_geom
    ADD CONSTRAINT land_assets_geom_pkey1 PRIMARY KEY (id);


--
-- Name: land_assets land_assets_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.land_assets
    ADD CONSTRAINT land_assets_pkey PRIMARY KEY (land_asset_id);


--
-- Name: land_parcels_geom land_parcels_geom_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.land_parcels_geom
    ADD CONSTRAINT land_parcels_geom_pkey PRIMARY KEY (id);


--
-- Name: land_parcels land_parcels_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.land_parcels
    ADD CONSTRAINT land_parcels_pkey PRIMARY KEY (land_parcel_id);


--
-- Name: notes notes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notes
    ADD CONSTRAINT notes_pkey PRIMARY KEY (note_id);


--
-- Name: person person_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.person
    ADD CONSTRAINT person_pkey PRIMARY KEY (person_id);


--
-- Name: replacement_structure_notes replacement_structure_notes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.replacement_structure_notes
    ADD CONSTRAINT replacement_structure_notes_pkey PRIMARY KEY (note_id);


--
-- Name: replacement_structure_types replacement_structure_types_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.replacement_structure_types
    ADD CONSTRAINT replacement_structure_types_pkey PRIMARY KEY (replacement_type_ref);


--
-- Name: replacement_structures replacement_structures_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.replacement_structures
    ADD CONSTRAINT replacement_structures_pkey PRIMARY KEY (replacement_structure_id);


--
-- Name: structures_geom structures_geom_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.structures_geom
    ADD CONSTRAINT structures_geom_pkey PRIMARY KEY (id);


--
-- Name: structures structures_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.structures
    ADD CONSTRAINT structures_pkey PRIMARY KEY (structure_id);


--
-- Name: tree_types tree_types_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tree_types
    ADD CONSTRAINT tree_types_pkey PRIMARY KEY (tree_type_id);


--
-- Name: trees trees_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trees
    ADD CONSTRAINT trees_pkey PRIMARY KEY (tree_id);


--
-- Name: user_login user_login_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_login
    ADD CONSTRAINT user_login_pkey PRIMARY KEY (user_id, login);


--
-- Name: user_pageview user_pageview_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_pageview
    ADD CONSTRAINT user_pageview_pkey PRIMARY KEY (user_id, page, viewtime);


--
-- Name: user user_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."user"
    ADD CONSTRAINT user_pkey PRIMARY KEY (user_id);


--
-- Name: usergroup usergroup_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.usergroup
    ADD CONSTRAINT usergroup_pkey PRIMARY KEY (usergroup_id);


--
-- Name: usergroup_user usergroup_user_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.usergroup_user
    ADD CONSTRAINT usergroup_user_pkey PRIMARY KEY (usergroup_id, user_id);


--
-- Name: villages villages_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.villages
    ADD CONSTRAINT villages_pkey PRIMARY KEY (village_id);


--
-- Name: zones zones_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.zones
    ADD CONSTRAINT zones_pkey PRIMARY KEY (id);


--
-- Name: indx_ crops_pah; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "indx_ crops_pah" ON public.crops USING btree (pah) WITH (deduplicate_items='true');


--
-- Name: indx_land_assets_parcel; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX indx_land_assets_parcel ON public.land_assets USING btree (land_parcel_id) WITH (deduplicate_items='true');


--
-- Name: indx_land_parcels_pah; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX indx_land_parcels_pah ON public.land_parcels USING btree (pah) WITH (deduplicate_items='true');


--
-- Name: indx_structs_pah; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX indx_structs_pah ON public.structures USING btree (pah) WITH (deduplicate_items='true');


--
-- Name: indx_trees; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX indx_trees ON public.trees USING btree (pah) WITH (deduplicate_items='true');


--
-- Name: sidx_impact_zones_geom; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX sidx_impact_zones_geom ON public.impact_zones USING gist (geom);


--
-- Name: sidx_land_assets_geom_geom; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX sidx_land_assets_geom_geom ON public.land_assets_geom USING gist (geom);


--
-- Name: sidx_land_parcels_geom_geom; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX sidx_land_parcels_geom_geom ON public.land_parcels_geom USING gist (geom);


--
-- Name: sidx_structures_geom_geom; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX sidx_structures_geom_geom ON public.structures_geom USING gist (geom);


--
-- Name: sidx_zones_geom; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX sidx_zones_geom ON public.zones USING gist (geom);


--
-- Name: fishers fishers_person_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.fishers
    ADD CONSTRAINT fishers_person_id_fkey FOREIGN KEY (person_id) REFERENCES public.person(person_id);


--
-- Name: grievances grievances_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.grievances
    ADD CONSTRAINT grievances_user_id_fkey FOREIGN KEY (user_id) REFERENCES public."user"(user_id);


--
-- Name: icas icas_nhs_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.icas
    ADD CONSTRAINT icas_nhs_fkey FOREIGN KEY (nhs) REFERENCES public.fishers(nhs);


--
-- Name: icas icas_pah_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.icas
    ADD CONSTRAINT icas_pah_fkey FOREIGN KEY (pah) REFERENCES public.households(pah);


--
-- Name: notes notes_nhs_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notes
    ADD CONSTRAINT notes_nhs_fkey FOREIGN KEY (nhs) REFERENCES public.fishers(nhs);


--
-- Name: replacement_structure_notes replacement_structure_notes_replacement_structure_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.replacement_structure_notes
    ADD CONSTRAINT replacement_structure_notes_replacement_structure_id_fkey FOREIGN KEY (replacement_structure_id) REFERENCES public.replacement_structures(replacement_structure_id);


--
-- Name: replacement_structure_notes replacement_structure_notes_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.replacement_structure_notes
    ADD CONSTRAINT replacement_structure_notes_user_id_fkey FOREIGN KEY (user_id) REFERENCES public."user"(user_id);


--
-- PostgreSQL database dump complete
--

