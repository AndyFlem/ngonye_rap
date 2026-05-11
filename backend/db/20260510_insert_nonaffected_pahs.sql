-- Insert 8 non-affected PAH households and their household heads
-- These PAHs had ICA PDFs locally but no DB records (Category 1 gap identified 2026-05-10)

BEGIN;

-- PAH163 Limpo Bwalya
INSERT INTO households (pah, nonaffected, allowance_disturbance, date_signed, ica_link)
VALUES (
    'PAH163',
    true,
    5000,
    '2024-06-01',
    'https://westernpower.sharepoint.com/sites/WPCWorking/Shared%20Documents/TEN%20Environmental%20and%20Social/E.45%20RAP/ICAs/PAHs/PAH163%20Limpo%20Bwalya.pdf'
);
WITH new_person AS (
    INSERT INTO person (pah, firstname, lastname, household_head)
    VALUES ('PAH163', 'Limpo', 'Bwalya', true)
    RETURNING person_id
)
UPDATE households SET householdhead_id = new_person.person_id
FROM new_person
WHERE households.pah = 'PAH163';
INSERT INTO notes (user_id, pah, note, created_at)
VALUES (1, 'PAH163', 'Inserted May 2026 for non-affected ICA on file', NOW());

-- PAH164 Masheke Lubasi
INSERT INTO households (pah, nonaffected, allowance_disturbance, date_signed, ica_link)
VALUES (
    'PAH164',
    true,
    5000,
    '2024-06-01',
    'https://westernpower.sharepoint.com/sites/WPCWorking/Shared%20Documents/TEN%20Environmental%20and%20Social/E.45%20RAP/ICAs/PAHs/PAH164%20Masheke%20Lubasi.pdf'
);
WITH new_person AS (
    INSERT INTO person (pah, firstname, lastname, household_head)
    VALUES ('PAH164', 'Masheke', 'Lubasi', true)
    RETURNING person_id
)
UPDATE households SET householdhead_id = new_person.person_id
FROM new_person
WHERE households.pah = 'PAH164';
INSERT INTO notes (user_id, pah, note, created_at)
VALUES (1, 'PAH164', 'Inserted May 2026 for non-affected ICA on file', NOW());

-- PAH165 Muyunda Mwikisa
INSERT INTO households (pah, nonaffected, allowance_disturbance, date_signed, ica_link)
VALUES (
    'PAH165',
    true,
    5000,
    '2024-06-01',
    'https://westernpower.sharepoint.com/sites/WPCWorking/Shared%20Documents/TEN%20Environmental%20and%20Social/E.45%20RAP/ICAs/PAHs/PAH165%20Muyunda%20Mwikisa.pdf'
);
WITH new_person AS (
    INSERT INTO person (pah, firstname, lastname, household_head)
    VALUES ('PAH165', 'Muyunda', 'Mwikisa', true)
    RETURNING person_id
)
UPDATE households SET householdhead_id = new_person.person_id
FROM new_person
WHERE households.pah = 'PAH165';
INSERT INTO notes (user_id, pah, note, created_at)
VALUES (1, 'PAH165', 'Inserted May 2026 for non-affected ICA on file', NOW());

-- PAH186 Lyamba Mubita
INSERT INTO households (pah, nonaffected, allowance_disturbance, date_signed, ica_link)
VALUES (
    'PAH186',
    true,
    5000,
    '2024-06-01',
    'https://westernpower.sharepoint.com/sites/WPCWorking/Shared%20Documents/TEN%20Environmental%20and%20Social/E.45%20RAP/ICAs/PAHs/PAH186%20Lyamba%20Mubita.pdf'
);
WITH new_person AS (
    INSERT INTO person (pah, firstname, lastname, household_head)
    VALUES ('PAH186', 'Lyamba', 'Mubita', true)
    RETURNING person_id
)
UPDATE households SET householdhead_id = new_person.person_id
FROM new_person
WHERE households.pah = 'PAH186';
INSERT INTO notes (user_id, pah, note, created_at)
VALUES (1, 'PAH186', 'Inserted May 2026 for non-affected ICA on file', NOW());

-- PAH212 Mutafela Lubasi
INSERT INTO households (pah, nonaffected, allowance_disturbance, date_signed, ica_link)
VALUES (
    'PAH212',
    true,
    5000,
    '2024-06-01',
    'https://westernpower.sharepoint.com/sites/WPCWorking/Shared%20Documents/TEN%20Environmental%20and%20Social/E.45%20RAP/ICAs/PAHs/PAH212%20Mutafela%20Lubasi.pdf'
);
WITH new_person AS (
    INSERT INTO person (pah, firstname, lastname, household_head)
    VALUES ('PAH212', 'Mutafela', 'Lubasi', true)
    RETURNING person_id
)
UPDATE households SET householdhead_id = new_person.person_id
FROM new_person
WHERE households.pah = 'PAH212';
INSERT INTO notes (user_id, pah, note, created_at)
VALUES (1, 'PAH212', 'Inserted May 2026 for non-affected ICA on file', NOW());

-- PAH287 Muyunda Mwikisa
INSERT INTO households (pah, nonaffected, allowance_disturbance, date_signed, ica_link)
VALUES (
    'PAH287',
    true,
    5000,
    '2024-06-01',
    'https://westernpower.sharepoint.com/sites/WPCWorking/Shared%20Documents/TEN%20Environmental%20and%20Social/E.45%20RAP/ICAs/PAHs/PAH287%20Muyunda%20Mwikisa.pdf'
);
WITH new_person AS (
    INSERT INTO person (pah, firstname, lastname, household_head)
    VALUES ('PAH287', 'Muyunda', 'Mwikisa', true)
    RETURNING person_id
)
UPDATE households SET householdhead_id = new_person.person_id
FROM new_person
WHERE households.pah = 'PAH287';
INSERT INTO notes (user_id, pah, note, created_at)
VALUES (1, 'PAH287', 'Inserted May 2026 for non-affected ICA on file', NOW());

-- PAH289 Kutiya Kafanu
INSERT INTO households (pah, nonaffected, allowance_disturbance, date_signed, ica_link)
VALUES (
    'PAH289',
    true,
    5000,
    '2024-06-01',
    'https://westernpower.sharepoint.com/sites/WPCWorking/Shared%20Documents/TEN%20Environmental%20and%20Social/E.45%20RAP/ICAs/PAHs/PAH289%20Kutiya%20Kafanu.pdf'
);
WITH new_person AS (
    INSERT INTO person (pah, firstname, lastname, household_head)
    VALUES ('PAH289', 'Kutiya', 'Kafanu', true)
    RETURNING person_id
)
UPDATE households SET householdhead_id = new_person.person_id
FROM new_person
WHERE households.pah = 'PAH289';
INSERT INTO notes (user_id, pah, note, created_at)
VALUES (1, 'PAH289', 'Inserted May 2026 for non-affected ICA on file', NOW());

-- PAH292 Masheke Lubasi
INSERT INTO households (pah, nonaffected, allowance_disturbance, date_signed, ica_link)
VALUES (
    'PAH292',
    true,
    5000,
    '2024-06-01',
    'https://westernpower.sharepoint.com/sites/WPCWorking/Shared%20Documents/TEN%20Environmental%20and%20Social/E.45%20RAP/ICAs/PAHs/PAH292%20Masheke%20Lubasi.pdf'
);
WITH new_person AS (
    INSERT INTO person (pah, firstname, lastname, household_head)
    VALUES ('PAH292', 'Masheke', 'Lubasi', true)
    RETURNING person_id
)
UPDATE households SET householdhead_id = new_person.person_id
FROM new_person
WHERE households.pah = 'PAH292';
INSERT INTO notes (user_id, pah, note, created_at)
VALUES (1, 'PAH292', 'Inserted May 2026 for non-affected ICA on file', NOW());

COMMIT;
