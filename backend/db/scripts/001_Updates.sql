begin;

update households set landholding_only=false where pah='PAH046';


update households set landholding_only=true where pah in (
SELECT 
	h.pah
from v_households h
where
	h.landholding_only = false
	and structures_count=0
	and 	(SELECT count(*) from land_parcels lp where lp.pah=h.pah and lp.land_class<>'Landholding')=0
	and (SELECT count(*) from land_parcels lp where lp.pah=h.pah and lp.land_class='Landholding')>0
)


update households set ica_type='Silumesii' where silumesii=true and ica_type='None';


update households set ica_type='ZRA' where pah='PAH047';

commit;