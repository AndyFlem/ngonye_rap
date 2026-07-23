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

update households set ica_type='Affected - ZRA' where ica_type='ZRA';
update households set ica_type='Affected - Silumesii' where ica_type='Silumesii';
update households set ica_type='Affected - Social' where ica_type='Social';
update households set ica_type='Disturbance only' where ica_type='Non-affected';

update replacement_structures set replacement_type_ref ='Church' where replacement_structure_id='RST103';
update replacement_structures set replacement_type_ref ='Church' where replacement_structure_id='RST104';
update replacement_structure_types set replacement_type_ref ='Church' where replacement_type_ref ='Cath Church';
delete from replacement_structure_types where replacement_type_ref ='SDA Church';
update replacement_structure_types set replacement_option ='Church' where replacement_type_ref ='Church';


commit;