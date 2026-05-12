BEGIN;

CREATE OR REPLACE VIEW public.v_fishers
 AS
SELECT
	f.nhs,
	f.person_id,
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
	((COALESCE(f.limbelo_traps,0) + COALESCE(f.maungwe_traps,0)) * 2 * 12.5) AS site_compensation_calc,
	GREATEST(
 	 (COALESCE(f.limbelo_traps, 0) + COALESCE(f.maungwe_traps, 0)) * 2 * 12.5,
  	500
	) as site_compensation,
	CASE
	  WHEN f.maungwe_active = 'Active'
	  THEN COALESCE(f.maungwe_traps,0)*1500
	  ELSE 0
	END	as maungwe_annual_earn,
	(COALESCE(f.limbelo_annual_buckets, 0)) as limbelo_annual_earn,
	(CASE
	  WHEN f.maungwe_active = 'Active'
	  THEN COALESCE(f.maungwe_traps,0)*1500
	  ELSE 0
	END) + (COALESCE(f.limbelo_annual_buckets, 0) * 332) as transitional_allowance
FROM
	fishers f;

ALTER TABLE public.v_fishers
    OWNER TO postgres;


COMMIT;