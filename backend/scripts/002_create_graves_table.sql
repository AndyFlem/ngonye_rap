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

COMMIT;
