-- Add SharePoint survey_link URLs to households_survey
-- Files exist for 80 of 87 PAHs; links are only set where a PDF exists on SharePoint.
-- PAHs with no file: PAH043, PAH375, PAH436, PAH438, PAH455, PAH458, PAH685

UPDATE households_survey
SET survey_link =
    'https://westernpower.sharepoint.com/:b:/r/sites/WPCWorking/Shared%20Documents/TEN%20Environmental%20and%20Social/E.45%20RAP/RAP%20Survey%20Forms/Socio-Asset%20Forms/PAH%20'
    || SUBSTRING(pah FROM 4)
    || '_socio_asset.pdf?csf=1&web=1&e=GXoKip'
WHERE pah IN (
    'PAH001', 'PAH002', 'PAH003', 'PAH004', 'PAH005',
    'PAH006', 'PAH007', 'PAH008', 'PAH009', 'PAH013',
    'PAH014', 'PAH018', 'PAH021', 'PAH022', 'PAH023',
    'PAH024', 'PAH025', 'PAH026', 'PAH028', 'PAH029',
    'PAH030', 'PAH033', 'PAH035', 'PAH039', 'PAH041',
    'PAH044', 'PAH046', 'PAH047', 'PAH048', 'PAH049',
    'PAH050', 'PAH051', 'PAH052', 'PAH053', 'PAH059',
    'PAH061', 'PAH062', 'PAH063', 'PAH064', 'PAH065',
    'PAH066', 'PAH067', 'PAH068', 'PAH069', 'PAH071',
    'PAH072', 'PAH079', 'PAH080', 'PAH081', 'PAH083',
    'PAH084', 'PAH085', 'PAH086', 'PAH087', 'PAH088',
    'PAH093', 'PAH094', 'PAH099', 'PAH100', 'PAH101',
    'PAH102', 'PAH103', 'PAH109', 'PAH110', 'PAH111',
    'PAH112', 'PAH113', 'PAH114', 'PAH115', 'PAH130',
    'PAH132', 'PAH133', 'PAH137', 'PAH143', 'PAH416',
    'PAH417', 'PAH418', 'PAH445', 'PAH454', 'PAH457'
);
