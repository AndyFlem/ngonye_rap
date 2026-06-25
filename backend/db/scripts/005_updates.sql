begin;

ALTER TABLE IF EXISTS public.grievances
    ADD COLUMN person_id bigint;

update grievances set person_id=householdhead_id from households h where grievances.pah=h.pah;    

update grievances set person_id=f.person_id from fishers f where grievances.nhs=f.nhs;

CREATE OR REPLACE VIEW  public.v_grievances
 AS
 SELECT 
 	g.grievance_id,
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
   FROM grievances g
   LEFT JOIN households h ON g.person_id=h.householdhead_id
   LEFT JOIN fishers f ON g.person_id=f.person_id
   LEFT JOIN v_person vf ON g.person_id=vf.person_id;

ALTER TABLE public.v_grievances
    OWNER TO postgres;


ALTER TABLE IF EXISTS public.grievances
    ALTER COLUMN person_id SET NOT NULL;
ALTER TABLE IF EXISTS public.grievances DROP CONSTRAINT IF EXISTS grievances_entity_check;

ALTER TABLE IF EXISTS public.grievances DROP COLUMN IF EXISTS pah;

ALTER TABLE IF EXISTS public.grievances DROP COLUMN IF EXISTS nhs;

commit;