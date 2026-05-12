begin;

-- Import signed ICAs for fishers (NHSs) from incoming_data/nhs_icas.csv.
-- SharePoint base: https://westernpower.sharepoint.com/:b:/r/sites/WPCWorking/Shared%20Documents/TEN%20Environmental%20and%20Social/E.45%20RAP/ICAs/NHSs/
--
-- Data notes:
--   - 18 malformed dates in CSV (commas instead of periods, trailing spaces) corrected inline.
--   - NHS196: CSV had "31.11.2023" (Nov has 30 days); corrected to 2023-11-30.
--   - NHS079: duplicate CSV row; inserted once.
--   - NHS026,056,067,081,119,141: two files each; correct file chosen by DB name lookup.
--   - NHS006,029,030,051,179: V2 file exists; original inserted as is_current=false, V2 as is_current=true.
--   - NHS065,085,100: V2 files exist but no CSV entry; skipped (signing date unknown).

insert into public.icas (nhs, date_signed, ica_link, type, is_current)
values
  ('NHS001', '2023-11-04', 'https://westernpower.sharepoint.com/:b:/r/sites/WPCWorking/Shared%20Documents/TEN%20Environmental%20and%20Social/E.45%20RAP/ICAs/NHSs/NHS001%20Chrispin%20Liwakala.pdf?csf=1&web=1', 'Fisher', true),
  ('NHS002', '2023-11-04', 'https://westernpower.sharepoint.com/:b:/r/sites/WPCWorking/Shared%20Documents/TEN%20Environmental%20and%20Social/E.45%20RAP/ICAs/NHSs/NHS002%20Francis%20Kutungula.PDF?csf=1&web=1', 'Fisher', true),
  ('NHS003', '2023-11-04', 'https://westernpower.sharepoint.com/:b:/r/sites/WPCWorking/Shared%20Documents/TEN%20Environmental%20and%20Social/E.45%20RAP/ICAs/NHSs/NHS003%20Alupili%20Edward.pdf?csf=1&web=1', 'Fisher', true),
  ('NHS004', '2023-11-04', 'https://westernpower.sharepoint.com/:b:/r/sites/WPCWorking/Shared%20Documents/TEN%20Environmental%20and%20Social/E.45%20RAP/ICAs/NHSs/NHS004%20Nyambe%20Nyambe.PDF?csf=1&web=1', 'Fisher', true),
  ('NHS005', '2023-11-04', 'https://westernpower.sharepoint.com/:b:/r/sites/WPCWorking/Shared%20Documents/TEN%20Environmental%20and%20Social/E.45%20RAP/ICAs/NHSs/NHS005%20Masiye%20Masiye.pdf?csf=1&web=1', 'Fisher', true),
  -- NHS006: V2 exists (signed 2024-06-01); original marked not current
  ('NHS006', '2023-11-04', 'https://westernpower.sharepoint.com/:b:/r/sites/WPCWorking/Shared%20Documents/TEN%20Environmental%20and%20Social/E.45%20RAP/ICAs/NHSs/NHS006%20Sikabongo%20Emilio.PDF?csf=1&web=1', 'Fisher', false),
  ('NHS006', '2024-06-01', 'https://westernpower.sharepoint.com/:b:/r/sites/WPCWorking/Shared%20Documents/TEN%20Environmental%20and%20Social/E.45%20RAP/ICAs/NHSs/NHS006%20Sikabongo%20Emilio%20V2%2020240601.pdf?csf=1&web=1', 'Fisher', true),
  ('NHS007', '2023-11-04', 'https://westernpower.sharepoint.com/:b:/r/sites/WPCWorking/Shared%20Documents/TEN%20Environmental%20and%20Social/E.45%20RAP/ICAs/NHSs/NHS007%20Mutandalo%20Muyanwa.PDF?csf=1&web=1', 'Fisher', true),
  ('NHS008', '2023-11-04', 'https://westernpower.sharepoint.com/:b:/r/sites/WPCWorking/Shared%20Documents/TEN%20Environmental%20and%20Social/E.45%20RAP/ICAs/NHSs/NHS008%20Nanalelwa%20Mwiya.pdf?csf=1&web=1', 'Fisher', true),
  ('NHS009', '2023-11-04', 'https://westernpower.sharepoint.com/:b:/r/sites/WPCWorking/Shared%20Documents/TEN%20Environmental%20and%20Social/E.45%20RAP/ICAs/NHSs/NHS009%20Lishomwa%20Liywalii.PDF?csf=1&web=1', 'Fisher', true),
  ('NHS010', '2023-11-04', 'https://westernpower.sharepoint.com/:b:/r/sites/WPCWorking/Shared%20Documents/TEN%20Environmental%20and%20Social/E.45%20RAP/ICAs/NHSs/NHS010%20Ilwendo%20Imbuwa.pdf?csf=1&web=1', 'Fisher', true),
  ('NHS011', '2023-11-04', 'https://westernpower.sharepoint.com/:b:/r/sites/WPCWorking/Shared%20Documents/TEN%20Environmental%20and%20Social/E.45%20RAP/ICAs/NHSs/NHS011%20Lucanana%20Lyatamani.pdf?csf=1&web=1', 'Fisher', true),
  ('NHS012', '2023-11-04', 'https://westernpower.sharepoint.com/:b:/r/sites/WPCWorking/Shared%20Documents/TEN%20Environmental%20and%20Social/E.45%20RAP/ICAs/NHSs/NHS012%20Liywalii%20Mulilo.pdf?csf=1&web=1', 'Fisher', true),
  ('NHS013', '2023-11-04', 'https://westernpower.sharepoint.com/:b:/r/sites/WPCWorking/Shared%20Documents/TEN%20Environmental%20and%20Social/E.45%20RAP/ICAs/NHSs/NHS013%20Nakamwelwa%20Kubaulila.PDF?csf=1&web=1', 'Fisher', true),
  ('NHS014', '2023-11-04', 'https://westernpower.sharepoint.com/:b:/r/sites/WPCWorking/Shared%20Documents/TEN%20Environmental%20and%20Social/E.45%20RAP/ICAs/NHSs/NHS014%20Wamunyima%20Mpango.PDF?csf=1&web=1', 'Fisher', true),
  ('NHS015', '2023-11-04', 'https://westernpower.sharepoint.com/:b:/r/sites/WPCWorking/Shared%20Documents/TEN%20Environmental%20and%20Social/E.45%20RAP/ICAs/NHSs/NHS015%20Alex%20Lyatamanyi.PDF?csf=1&web=1', 'Fisher', true),
  ('NHS016', '2023-11-04', 'https://westernpower.sharepoint.com/:b:/r/sites/WPCWorking/Shared%20Documents/TEN%20Environmental%20and%20Social/E.45%20RAP/ICAs/NHSs/NHS016%20Nyimbwa%20Muliya.PDF?csf=1&web=1', 'Fisher', true),
  ('NHS017', '2023-11-04', 'https://westernpower.sharepoint.com/:b:/r/sites/WPCWorking/Shared%20Documents/TEN%20Environmental%20and%20Social/E.45%20RAP/ICAs/NHSs/NHS017%20Chilindi%20Namasiku.PDF?csf=1&web=1', 'Fisher', true),
  ('NHS018', '2023-11-04', 'https://westernpower.sharepoint.com/:b:/r/sites/WPCWorking/Shared%20Documents/TEN%20Environmental%20and%20Social/E.45%20RAP/ICAs/NHSs/NHS018%20Mutumwa%20Nyambe.PDF?csf=1&web=1', 'Fisher', true),
  ('NHS019', '2023-11-04', 'https://westernpower.sharepoint.com/:b:/r/sites/WPCWorking/Shared%20Documents/TEN%20Environmental%20and%20Social/E.45%20RAP/ICAs/NHSs/NHS019%20Lubinda%20Mukela.PDF?csf=1&web=1', 'Fisher', true),
  ('NHS021', '2023-11-04', 'https://westernpower.sharepoint.com/:b:/r/sites/WPCWorking/Shared%20Documents/TEN%20Environmental%20and%20Social/E.45%20RAP/ICAs/NHSs/NHS021%20Nawa%20Kwakana.PDF?csf=1&web=1', 'Fisher', true),
  ('NHS022', '2023-11-07', 'https://westernpower.sharepoint.com/:b:/r/sites/WPCWorking/Shared%20Documents/TEN%20Environmental%20and%20Social/E.45%20RAP/ICAs/NHSs/NHS022%20Mubita%20Sifaya.PDF?csf=1&web=1', 'Fisher', true),
  ('NHS023', '2023-11-03', 'https://westernpower.sharepoint.com/:b:/r/sites/WPCWorking/Shared%20Documents/TEN%20Environmental%20and%20Social/E.45%20RAP/ICAs/NHSs/NHS023%20Musiwa%20Musiyalela.PDF?csf=1&web=1', 'Fisher', true),
  ('NHS024', '2023-11-04', 'https://westernpower.sharepoint.com/:b:/r/sites/WPCWorking/Shared%20Documents/TEN%20Environmental%20and%20Social/E.45%20RAP/ICAs/NHSs/NHS024%20Pelekelo%20Makumbi.PDF?csf=1&web=1', 'Fisher', true),
  ('NHS025', '2023-11-01', 'https://westernpower.sharepoint.com/:b:/r/sites/WPCWorking/Shared%20Documents/TEN%20Environmental%20and%20Social/E.45%20RAP/ICAs/NHSs/NHS025%20Sitali%20Matale.PDF?csf=1&web=1', 'Fisher', true),
  -- NHS026: "Monaliywa Kabuku.PDF" rejected; correct spelling is Mumonaliywa
  ('NHS026', '2023-11-04', 'https://westernpower.sharepoint.com/:b:/r/sites/WPCWorking/Shared%20Documents/TEN%20Environmental%20and%20Social/E.45%20RAP/ICAs/NHSs/NHS026%20Mumonaliywa%20Kabuku.pdf?csf=1&web=1', 'Fisher', true),
  ('NHS027', '2023-11-01', 'https://westernpower.sharepoint.com/:b:/r/sites/WPCWorking/Shared%20Documents/TEN%20Environmental%20and%20Social/E.45%20RAP/ICAs/NHSs/NHS027%20Mabuku%20Sanyambe.PDF?csf=1&web=1', 'Fisher', true),
  ('NHS028', '2023-11-01', 'https://westernpower.sharepoint.com/:b:/r/sites/WPCWorking/Shared%20Documents/TEN%20Environmental%20and%20Social/E.45%20RAP/ICAs/NHSs/NHS028%20Nasilele%20Kalaluka.PDF?csf=1&web=1', 'Fisher', true),
  -- NHS029: V2 exists (signed 2026-02-04); original marked not current
  ('NHS029', '2023-11-01', 'https://westernpower.sharepoint.com/:b:/r/sites/WPCWorking/Shared%20Documents/TEN%20Environmental%20and%20Social/E.45%20RAP/ICAs/NHSs/NHS029%20Sikwatiketo%20Matale.pdf?csf=1&web=1', 'Fisher', false),
  ('NHS029', '2026-02-04', 'https://westernpower.sharepoint.com/:b:/r/sites/WPCWorking/Shared%20Documents/TEN%20Environmental%20and%20Social/E.45%20RAP/ICAs/NHSs/NHS029%20Sikwatiketo%20Matale%20V2%2020260204.pdf?csf=1&web=1', 'Fisher', true),
  -- NHS030: V2 exists (signed 2026-02-04); original marked not current
  ('NHS030', '2023-11-01', 'https://westernpower.sharepoint.com/:b:/r/sites/WPCWorking/Shared%20Documents/TEN%20Environmental%20and%20Social/E.45%20RAP/ICAs/NHSs/NHS030%20Livinasi%20Litaba.PDF?csf=1&web=1', 'Fisher', false),
  ('NHS030', '2026-02-04', 'https://westernpower.sharepoint.com/:b:/r/sites/WPCWorking/Shared%20Documents/TEN%20Environmental%20and%20Social/E.45%20RAP/ICAs/NHSs/NHS030%20Livinasi%20Litaba%20V2%2020260204.pdf?csf=1&web=1', 'Fisher', true),
  ('NHS031', '2023-11-01', 'https://westernpower.sharepoint.com/:b:/r/sites/WPCWorking/Shared%20Documents/TEN%20Environmental%20and%20Social/E.45%20RAP/ICAs/NHSs/NHS031%20Lawrence%20Matale.pdf?csf=1&web=1', 'Fisher', true),
  ('NHS032', '2023-11-01', 'https://westernpower.sharepoint.com/:b:/r/sites/WPCWorking/Shared%20Documents/TEN%20Environmental%20and%20Social/E.45%20RAP/ICAs/NHSs/NHS032%20Liywalii%20Liywalii.pdf?csf=1&web=1', 'Fisher', true),
  ('NHS033', '2023-11-01', 'https://westernpower.sharepoint.com/:b:/r/sites/WPCWorking/Shared%20Documents/TEN%20Environmental%20and%20Social/E.45%20RAP/ICAs/NHSs/NHS033%20Alfred%20Pumulo%20Matale.PDF?csf=1&web=1', 'Fisher', true),
  ('NHS034', '2023-11-01', 'https://westernpower.sharepoint.com/:b:/r/sites/WPCWorking/Shared%20Documents/TEN%20Environmental%20and%20Social/E.45%20RAP/ICAs/NHSs/NHS034%20Mbano%20Miliko.PDF?csf=1&web=1', 'Fisher', true),
  ('NHS035', '2023-11-04', 'https://westernpower.sharepoint.com/:b:/r/sites/WPCWorking/Shared%20Documents/TEN%20Environmental%20and%20Social/E.45%20RAP/ICAs/NHSs/NHS035%20Mashewani%20Kabuku.PDF?csf=1&web=1', 'Fisher', true),
  ('NHS036', '2023-11-05', 'https://westernpower.sharepoint.com/:b:/r/sites/WPCWorking/Shared%20Documents/TEN%20Environmental%20and%20Social/E.45%20RAP/ICAs/NHSs/NHS036%20Kayombo%20Mubita.PDF?csf=1&web=1', 'Fisher', true),
  ('NHS038', '2023-11-01', 'https://westernpower.sharepoint.com/:b:/r/sites/WPCWorking/Shared%20Documents/TEN%20Environmental%20and%20Social/E.45%20RAP/ICAs/NHSs/NHS038%20Maria%20Mwipi.PDF?csf=1&web=1', 'Fisher', true),
  ('NHS039', '2023-11-01', 'https://westernpower.sharepoint.com/:b:/r/sites/WPCWorking/Shared%20Documents/TEN%20Environmental%20and%20Social/E.45%20RAP/ICAs/NHSs/NHS039%20Mbololwa%20Songa.PDF?csf=1&web=1', 'Fisher', true),
  ('NHS040', '2023-11-01', 'https://westernpower.sharepoint.com/:b:/r/sites/WPCWorking/Shared%20Documents/TEN%20Environmental%20and%20Social/E.45%20RAP/ICAs/NHSs/NHS040%20Moola%20Kayuni.PDF?csf=1&web=1', 'Fisher', true),
  -- NHS041: filename has a trailing space before extension on disk
  ('NHS041', '2023-11-01', 'https://westernpower.sharepoint.com/:b:/r/sites/WPCWorking/Shared%20Documents/TEN%20Environmental%20and%20Social/E.45%20RAP/ICAs/NHSs/NHS041%20Munyumba%20Mundia%20.PDF?csf=1&web=1', 'Fisher', true),
  ('NHS042', '2023-11-01', 'https://westernpower.sharepoint.com/:b:/r/sites/WPCWorking/Shared%20Documents/TEN%20Environmental%20and%20Social/E.45%20RAP/ICAs/NHSs/NHS042%20Mebelo%20Mundia.PDF?csf=1&web=1', 'Fisher', true),
  ('NHS043', '2023-11-01', 'https://westernpower.sharepoint.com/:b:/r/sites/WPCWorking/Shared%20Documents/TEN%20Environmental%20and%20Social/E.45%20RAP/ICAs/NHSs/NHS043%20Mukitwa%20Mukitwa.PDF?csf=1&web=1', 'Fisher', true),
  ('NHS044', '2023-11-05', 'https://westernpower.sharepoint.com/:b:/r/sites/WPCWorking/Shared%20Documents/TEN%20Environmental%20and%20Social/E.45%20RAP/ICAs/NHSs/NHS044%20Kabombo%20Kanwa.PDF?csf=1&web=1', 'Fisher', true),
  ('NHS045', '2023-04-01', 'https://westernpower.sharepoint.com/:b:/r/sites/WPCWorking/Shared%20Documents/TEN%20Environmental%20and%20Social/E.45%20RAP/ICAs/NHSs/NHS045%20Mwiya%20Musiwa.PDF?csf=1&web=1', 'Fisher', true),
  ('NHS046', '2023-11-01', 'https://westernpower.sharepoint.com/:b:/r/sites/WPCWorking/Shared%20Documents/TEN%20Environmental%20and%20Social/E.45%20RAP/ICAs/NHSs/NHS046%20Mwiya%20Mwiya.PDF?csf=1&web=1', 'Fisher', true),
  ('NHS047', '2023-11-01', 'https://westernpower.sharepoint.com/:b:/r/sites/WPCWorking/Shared%20Documents/TEN%20Environmental%20and%20Social/E.45%20RAP/ICAs/NHSs/NHS047%20Matomola%20Mundia.PDF?csf=1&web=1', 'Fisher', true),
  ('NHS048', '2023-11-01', 'https://westernpower.sharepoint.com/:b:/r/sites/WPCWorking/Shared%20Documents/TEN%20Environmental%20and%20Social/E.45%20RAP/ICAs/NHSs/NHS048%20Sibote%20Mangala.PDF?csf=1&web=1', 'Fisher', true),
  ('NHS050', '2023-11-07', 'https://westernpower.sharepoint.com/:b:/r/sites/WPCWorking/Shared%20Documents/TEN%20Environmental%20and%20Social/E.45%20RAP/ICAs/NHSs/NHS050%20Joseph%20Mwiya.pdf?csf=1&web=1', 'Fisher', true),
  -- NHS051: V2 exists (signed 2024-05-21); original marked not current
  ('NHS051', '2023-11-01', 'https://westernpower.sharepoint.com/:b:/r/sites/WPCWorking/Shared%20Documents/TEN%20Environmental%20and%20Social/E.45%20RAP/ICAs/NHSs/NHS051%20Nandila%20Mwiya.pdf?csf=1&web=1', 'Fisher', false),
  ('NHS051', '2024-05-21', 'https://westernpower.sharepoint.com/:b:/r/sites/WPCWorking/Shared%20Documents/TEN%20Environmental%20and%20Social/E.45%20RAP/ICAs/NHSs/NHS051%20Nandila%20Mwiya%20V2%2020240521.pdf?csf=1&web=1', 'Fisher', true),
  -- NHS052: CSV had "01.11,2023" (comma); corrected to 2023-11-01
  ('NHS052', '2023-11-01', 'https://westernpower.sharepoint.com/:b:/r/sites/WPCWorking/Shared%20Documents/TEN%20Environmental%20and%20Social/E.45%20RAP/ICAs/NHSs/NHS052%20Matomola%20Matomola.PDF?csf=1&web=1', 'Fisher', true),
  ('NHS053', '2023-11-01', 'https://westernpower.sharepoint.com/:b:/r/sites/WPCWorking/Shared%20Documents/TEN%20Environmental%20and%20Social/E.45%20RAP/ICAs/NHSs/NHS053%20Emmanuel%20Kangumu.pdf?csf=1&web=1', 'Fisher', true),
  ('NHS054', '2023-11-01', 'https://westernpower.sharepoint.com/:b:/r/sites/WPCWorking/Shared%20Documents/TEN%20Environmental%20and%20Social/E.45%20RAP/ICAs/NHSs/NHS054%20Zinkinyeho%20Pelekelo.pdf?csf=1&web=1', 'Fisher', true),
  ('NHS055', '2023-11-07', 'https://westernpower.sharepoint.com/:b:/r/sites/WPCWorking/Shared%20Documents/TEN%20Environmental%20and%20Social/E.45%20RAP/ICAs/NHSs/NHS055%20Kwekeza%20Silindi.pdf?csf=1&web=1', 'Fisher', true),
  -- NHS056: "Muyunda Muchaulo.PDF" rejected; correct surname is Mucaulo
  ('NHS056', '2023-11-01', 'https://westernpower.sharepoint.com/:b:/r/sites/WPCWorking/Shared%20Documents/TEN%20Environmental%20and%20Social/E.45%20RAP/ICAs/NHSs/NHS056%20Muyunda%20Mucaulo.pdf?csf=1&web=1', 'Fisher', true),
  ('NHS057', '2023-11-05', 'https://westernpower.sharepoint.com/:b:/r/sites/WPCWorking/Shared%20Documents/TEN%20Environmental%20and%20Social/E.45%20RAP/ICAs/NHSs/NHS057%20Samanga%20Mafa.PDF?csf=1&web=1', 'Fisher', true),
  ('NHS058', '2023-11-01', 'https://westernpower.sharepoint.com/:b:/r/sites/WPCWorking/Shared%20Documents/TEN%20Environmental%20and%20Social/E.45%20RAP/ICAs/NHSs/NHS058%20Sakuba%20Sakuba.PDF?csf=1&web=1', 'Fisher', true),
  ('NHS059', '2023-11-01', 'https://westernpower.sharepoint.com/:b:/r/sites/WPCWorking/Shared%20Documents/TEN%20Environmental%20and%20Social/E.45%20RAP/ICAs/NHSs/NHS059%20Mubita%20Katobela.PDF?csf=1&web=1', 'Fisher', true),
  ('NHS060', '2023-11-01', 'https://westernpower.sharepoint.com/:b:/r/sites/WPCWorking/Shared%20Documents/TEN%20Environmental%20and%20Social/E.45%20RAP/ICAs/NHSs/NHS060%20Mafaya%20Mafaya.PDF?csf=1&web=1', 'Fisher', true),
  ('NHS061', '2023-11-01', 'https://westernpower.sharepoint.com/:b:/r/sites/WPCWorking/Shared%20Documents/TEN%20Environmental%20and%20Social/E.45%20RAP/ICAs/NHSs/NHS061%20Manyando%20Muwanei.PDF?csf=1&web=1', 'Fisher', true),
  ('NHS062', '2023-11-07', 'https://westernpower.sharepoint.com/:b:/r/sites/WPCWorking/Shared%20Documents/TEN%20Environmental%20and%20Social/E.45%20RAP/ICAs/NHSs/NHS062%20Inambao%20Matomola.PDF?csf=1&web=1', 'Fisher', true),
  ('NHS063', '2023-11-01', 'https://westernpower.sharepoint.com/:b:/r/sites/WPCWorking/Shared%20Documents/TEN%20Environmental%20and%20Social/E.45%20RAP/ICAs/NHSs/NHS063%20Sitali%20Siyanga.PDF?csf=1&web=1', 'Fisher', true),
  ('NHS064', '2023-11-01', 'https://westernpower.sharepoint.com/:b:/r/sites/WPCWorking/Shared%20Documents/TEN%20Environmental%20and%20Social/E.45%20RAP/ICAs/NHSs/NHS064%20Chingumbe%20Chingumbe.PDF?csf=1&web=1', 'Fisher', true),
  ('NHS066', '2023-11-01', 'https://westernpower.sharepoint.com/:b:/r/sites/WPCWorking/Shared%20Documents/TEN%20Environmental%20and%20Social/E.45%20RAP/ICAs/NHSs/NHS066%20Sikombwa%20Mwala.PDF?csf=1&web=1', 'Fisher', true),
  -- NHS067: "Imataa Nwauluka.pdf" rejected; correct surname is Mwauluka
  ('NHS067', '2023-11-05', 'https://westernpower.sharepoint.com/:b:/r/sites/WPCWorking/Shared%20Documents/TEN%20Environmental%20and%20Social/E.45%20RAP/ICAs/NHSs/NHS067%20Imataa%20Mwauluka.PDF?csf=1&web=1', 'Fisher', true),
  ('NHS068', '2023-10-31', 'https://westernpower.sharepoint.com/:b:/r/sites/WPCWorking/Shared%20Documents/TEN%20Environmental%20and%20Social/E.45%20RAP/ICAs/NHSs/NHS068%20Sikumbwa%20Kupenga.PDF?csf=1&web=1', 'Fisher', true),
  ('NHS069', '2023-10-31', 'https://westernpower.sharepoint.com/:b:/r/sites/WPCWorking/Shared%20Documents/TEN%20Environmental%20and%20Social/E.45%20RAP/ICAs/NHSs/NHS069%20Sikombwa%20Mabuta.PDF?csf=1&web=1', 'Fisher', true),
  ('NHS070', '2023-11-01', 'https://westernpower.sharepoint.com/:b:/r/sites/WPCWorking/Shared%20Documents/TEN%20Environmental%20and%20Social/E.45%20RAP/ICAs/NHSs/NHS070%20Moses%20Mwauluka.PDF?csf=1&web=1', 'Fisher', true),
  ('NHS071', '2023-11-08', 'https://westernpower.sharepoint.com/:b:/r/sites/WPCWorking/Shared%20Documents/TEN%20Environmental%20and%20Social/E.45%20RAP/ICAs/NHSs/NHS071%20Nalumo%20Sifungwa.PDF?csf=1&web=1', 'Fisher', true),
  ('NHS072', '2023-11-08', 'https://westernpower.sharepoint.com/:b:/r/sites/WPCWorking/Shared%20Documents/TEN%20Environmental%20and%20Social/E.45%20RAP/ICAs/NHSs/NHS072%20Mwanangombe%20Matongo.PDF?csf=1&web=1', 'Fisher', true),
  ('NHS073', '2023-11-02', 'https://westernpower.sharepoint.com/:b:/r/sites/WPCWorking/Shared%20Documents/TEN%20Environmental%20and%20Social/E.45%20RAP/ICAs/NHSs/NHS073%20Mulonda%20Mubita.PDF?csf=1&web=1', 'Fisher', true),
  ('NHS074', '2023-11-01', 'https://westernpower.sharepoint.com/:b:/r/sites/WPCWorking/Shared%20Documents/TEN%20Environmental%20and%20Social/E.45%20RAP/ICAs/NHSs/NHS074%20Sitali%20Sitali.PDF?csf=1&web=1', 'Fisher', true),
  ('NHS075', '2023-10-31', 'https://westernpower.sharepoint.com/:b:/r/sites/WPCWorking/Shared%20Documents/TEN%20Environmental%20and%20Social/E.45%20RAP/ICAs/NHSs/NHS075%20Robert%20Mubita.PDF?csf=1&web=1', 'Fisher', true),
  -- NHS076: CSV had "31,10,2023" (commas); corrected to 2023-10-31
  ('NHS076', '2023-10-31', 'https://westernpower.sharepoint.com/:b:/r/sites/WPCWorking/Shared%20Documents/TEN%20Environmental%20and%20Social/E.45%20RAP/ICAs/NHSs/NHS076%20Mukwamandi%20Mubita.PDF?csf=1&web=1', 'Fisher', true),
  -- NHS077: CSV had "01.11,2023" (comma); corrected to 2023-11-01
  ('NHS077', '2023-11-01', 'https://westernpower.sharepoint.com/:b:/r/sites/WPCWorking/Shared%20Documents/TEN%20Environmental%20and%20Social/E.45%20RAP/ICAs/NHSs/NHS077%20Mwanja%20Mundia.PDF?csf=1&web=1', 'Fisher', true),
  -- NHS078: CSV had trailing space in date; corrected
  ('NHS078', '2023-12-11', 'https://westernpower.sharepoint.com/:b:/r/sites/WPCWorking/Shared%20Documents/TEN%20Environmental%20and%20Social/E.45%20RAP/ICAs/NHSs/NHS078%20Lyambela%20Kunyanda.PDF?csf=1&web=1', 'Fisher', true),
  -- NHS079: duplicate CSV row; inserted once
  ('NHS079', '2023-10-31', 'https://westernpower.sharepoint.com/:b:/r/sites/WPCWorking/Shared%20Documents/TEN%20Environmental%20and%20Social/E.45%20RAP/ICAs/NHSs/NHS079%20Patrick%20Mwauluka.PDF?csf=1&web=1', 'Fisher', true),
  ('NHS080', '2023-10-31', 'https://westernpower.sharepoint.com/:b:/r/sites/WPCWorking/Shared%20Documents/TEN%20Environmental%20and%20Social/E.45%20RAP/ICAs/NHSs/NHS080%20Mwaluka%20Kupenga.PDF?csf=1&web=1', 'Fisher', true),
  -- NHS081: "Muyendekwa Likando.pdf" rejected (misfiled); correct person is Nang'unyi Mwauluka
  ('NHS081', '2023-11-01', 'https://westernpower.sharepoint.com/:b:/r/sites/WPCWorking/Shared%20Documents/TEN%20Environmental%20and%20Social/E.45%20RAP/ICAs/NHSs/NHS081%20Nanunyi%20Mwauluka.PDF?csf=1&web=1', 'Fisher', true),
  ('NHS082', '2023-10-31', 'https://westernpower.sharepoint.com/:b:/r/sites/WPCWorking/Shared%20Documents/TEN%20Environmental%20and%20Social/E.45%20RAP/ICAs/NHSs/NHS082%20Nalishebo%20Mubita.PDF?csf=1&web=1', 'Fisher', true),
  ('NHS083', '2023-11-05', 'https://westernpower.sharepoint.com/:b:/r/sites/WPCWorking/Shared%20Documents/TEN%20Environmental%20and%20Social/E.45%20RAP/ICAs/NHSs/NHS083%20Imasiku%20Mwauluka.PDF?csf=1&web=1', 'Fisher', true),
  ('NHS084', '2023-10-31', 'https://westernpower.sharepoint.com/:b:/r/sites/WPCWorking/Shared%20Documents/TEN%20Environmental%20and%20Social/E.45%20RAP/ICAs/NHSs/NHS084%20Lubasi%20Imataa.PDF?csf=1&web=1', 'Fisher', true),
  -- NHS086: CSV had "01,11,2023" (commas); corrected to 2023-11-01
  ('NHS086', '2023-11-01', 'https://westernpower.sharepoint.com/:b:/r/sites/WPCWorking/Shared%20Documents/TEN%20Environmental%20and%20Social/E.45%20RAP/ICAs/NHSs/NHS086%20Sikwati%20Bertha.PDF?csf=1&web=1', 'Fisher', true),
  ('NHS087', '2023-10-31', 'https://westernpower.sharepoint.com/:b:/r/sites/WPCWorking/Shared%20Documents/TEN%20Environmental%20and%20Social/E.45%20RAP/ICAs/NHSs/NHS087%20Makandauko%20Imasiku.PDF?csf=1&web=1', 'Fisher', true),
  ('NHS088', '2023-10-31', 'https://westernpower.sharepoint.com/:b:/r/sites/WPCWorking/Shared%20Documents/TEN%20Environmental%20and%20Social/E.45%20RAP/ICAs/NHSs/NHS088%20Maketo%20Ilukena.PDF?csf=1&web=1', 'Fisher', true),
  ('NHS089', '2023-10-31', 'https://westernpower.sharepoint.com/:b:/r/sites/WPCWorking/Shared%20Documents/TEN%20Environmental%20and%20Social/E.45%20RAP/ICAs/NHSs/NHS089%20Matongo%20Matongo.PDF?csf=1&web=1', 'Fisher', true),
  ('NHS091', '2023-10-31', 'https://westernpower.sharepoint.com/:b:/r/sites/WPCWorking/Shared%20Documents/TEN%20Environmental%20and%20Social/E.45%20RAP/ICAs/NHSs/NHS091%20Siteleki%20Leckses.pdf?csf=1&web=1', 'Fisher', true),
  ('NHS092', '2023-10-31', 'https://westernpower.sharepoint.com/:b:/r/sites/WPCWorking/Shared%20Documents/TEN%20Environmental%20and%20Social/E.45%20RAP/ICAs/NHSs/NHS092%20Makandauko%20Mwala.PDF?csf=1&web=1', 'Fisher', true),
  ('NHS093', '2023-11-01', 'https://westernpower.sharepoint.com/:b:/r/sites/WPCWorking/Shared%20Documents/TEN%20Environmental%20and%20Social/E.45%20RAP/ICAs/NHSs/NHS093%20Sikombwa%20Mabuta.PDF?csf=1&web=1', 'Fisher', true),
  ('NHS094', '2023-11-01', 'https://westernpower.sharepoint.com/:b:/r/sites/WPCWorking/Shared%20Documents/TEN%20Environmental%20and%20Social/E.45%20RAP/ICAs/NHSs/NHS094%20Mulomba%20Matakala.PDF?csf=1&web=1', 'Fisher', true),
  ('NHS096', '2023-11-02', 'https://westernpower.sharepoint.com/:b:/r/sites/WPCWorking/Shared%20Documents/TEN%20Environmental%20and%20Social/E.45%20RAP/ICAs/NHSs/NHS096%20Lubinda%20Lyambela.PDF?csf=1&web=1', 'Fisher', true),
  ('NHS097', '2023-11-01', 'https://westernpower.sharepoint.com/:b:/r/sites/WPCWorking/Shared%20Documents/TEN%20Environmental%20and%20Social/E.45%20RAP/ICAs/NHSs/NHS097%20Mutafela%20Malumo.PDF?csf=1&web=1', 'Fisher', true),
  ('NHS098', '2023-11-02', 'https://westernpower.sharepoint.com/:b:/r/sites/WPCWorking/Shared%20Documents/TEN%20Environmental%20and%20Social/E.45%20RAP/ICAs/NHSs/NHS098%20Mulomba%20Mulobela.PDF?csf=1&web=1', 'Fisher', true),
  ('NHS099', '2023-11-01', 'https://westernpower.sharepoint.com/:b:/r/sites/WPCWorking/Shared%20Documents/TEN%20Environmental%20and%20Social/E.45%20RAP/ICAs/NHSs/NHS099%20Frank%20Liywalii.PDF?csf=1&web=1', 'Fisher', true),
  -- NHS101: CSV had "01.11,2023" (comma); corrected to 2023-11-01
  ('NHS101', '2023-11-01', 'https://westernpower.sharepoint.com/:b:/r/sites/WPCWorking/Shared%20Documents/TEN%20Environmental%20and%20Social/E.45%20RAP/ICAs/NHSs/NHS101%20Wamui%20Kwalombota.PDF?csf=1&web=1', 'Fisher', true),
  ('NHS102', '2023-11-08', 'https://westernpower.sharepoint.com/:b:/r/sites/WPCWorking/Shared%20Documents/TEN%20Environmental%20and%20Social/E.45%20RAP/ICAs/NHSs/NHS102%20Namakando%20Likezo.PDF?csf=1&web=1', 'Fisher', true),
  ('NHS103', '2023-11-01', 'https://westernpower.sharepoint.com/:b:/r/sites/WPCWorking/Shared%20Documents/TEN%20Environmental%20and%20Social/E.45%20RAP/ICAs/NHSs/NHS103%20Sepiso%20Mutokomela.PDF?csf=1&web=1', 'Fisher', true),
  ('NHS104', '2023-11-01', 'https://westernpower.sharepoint.com/:b:/r/sites/WPCWorking/Shared%20Documents/TEN%20Environmental%20and%20Social/E.45%20RAP/ICAs/NHSs/NHS104%20Malunga%20Muka.PDF?csf=1&web=1', 'Fisher', true),
  ('NHS105', '2023-11-08', 'https://westernpower.sharepoint.com/:b:/r/sites/WPCWorking/Shared%20Documents/TEN%20Environmental%20and%20Social/E.45%20RAP/ICAs/NHSs/NHS105%20Lubinda%20Mate.PDF?csf=1&web=1', 'Fisher', true),
  ('NHS106', '2023-11-01', 'https://westernpower.sharepoint.com/:b:/r/sites/WPCWorking/Shared%20Documents/TEN%20Environmental%20and%20Social/E.45%20RAP/ICAs/NHSs/NHS106%20Taulo%20Peter.PDF?csf=1&web=1', 'Fisher', true),
  ('NHS107', '2023-11-02', 'https://westernpower.sharepoint.com/:b:/r/sites/WPCWorking/Shared%20Documents/TEN%20Environmental%20and%20Social/E.45%20RAP/ICAs/NHSs/NHS107%20Saloba%20Milapo.PDF?csf=1&web=1', 'Fisher', true),
  ('NHS108', '2023-11-02', 'https://westernpower.sharepoint.com/:b:/r/sites/WPCWorking/Shared%20Documents/TEN%20Environmental%20and%20Social/E.45%20RAP/ICAs/NHSs/NHS108%20Collins%20Mululu.PDF?csf=1&web=1', 'Fisher', true),
  ('NHS109', '2023-11-02', 'https://westernpower.sharepoint.com/:b:/r/sites/WPCWorking/Shared%20Documents/TEN%20Environmental%20and%20Social/E.45%20RAP/ICAs/NHSs/NHS109%20Lifumbela%20Mahupulo.PDF?csf=1&web=1', 'Fisher', true),
  -- NHS110: CSV had "08.11,2023" (comma); corrected to 2023-11-08
  ('NHS110', '2023-11-08', 'https://westernpower.sharepoint.com/:b:/r/sites/WPCWorking/Shared%20Documents/TEN%20Environmental%20and%20Social/E.45%20RAP/ICAs/NHSs/NHS110%20Mwauluka%20Lyambela.PDF?csf=1&web=1', 'Fisher', true),
  ('NHS112', '2023-11-06', 'https://westernpower.sharepoint.com/:b:/r/sites/WPCWorking/Shared%20Documents/TEN%20Environmental%20and%20Social/E.45%20RAP/ICAs/NHSs/NHS112%20Minyoi%20Mabumbo.pdf?csf=1&web=1', 'Fisher', true),
  ('NHS113', '2023-11-06', 'https://westernpower.sharepoint.com/:b:/r/sites/WPCWorking/Shared%20Documents/TEN%20Environmental%20and%20Social/E.45%20RAP/ICAs/NHSs/NHS113%20Musiyalela%20Patrick.PDF?csf=1&web=1', 'Fisher', true),
  ('NHS114', '2023-11-01', 'https://westernpower.sharepoint.com/:b:/r/sites/WPCWorking/Shared%20Documents/TEN%20Environmental%20and%20Social/E.45%20RAP/ICAs/NHSs/NHS114%20Mulomba%20Simalumba.PDF?csf=1&web=1', 'Fisher', true),
  ('NHS116', '2023-11-01', 'https://westernpower.sharepoint.com/:b:/r/sites/WPCWorking/Shared%20Documents/TEN%20Environmental%20and%20Social/E.45%20RAP/ICAs/NHSs/NHS116%20Lubango%20Kase.PDF?csf=1&web=1', 'Fisher', true),
  ('NHS117', '2023-11-01', 'https://westernpower.sharepoint.com/:b:/r/sites/WPCWorking/Shared%20Documents/TEN%20Environmental%20and%20Social/E.45%20RAP/ICAs/NHSs/NHS117%20Mukendwa%20Matakala.PDF?csf=1&web=1', 'Fisher', true),
  ('NHS118', '2023-11-01', 'https://westernpower.sharepoint.com/:b:/r/sites/WPCWorking/Shared%20Documents/TEN%20Environmental%20and%20Social/E.45%20RAP/ICAs/NHSs/NHS118%20Mululu%20Mundila.PDF?csf=1&web=1', 'Fisher', true),
  -- NHS119: "Nanalelwa Likando.pdf" rejected (misfiled); correct person is Muchaulo Mwiiba
  ('NHS119', '2023-11-01', 'https://westernpower.sharepoint.com/:b:/r/sites/WPCWorking/Shared%20Documents/TEN%20Environmental%20and%20Social/E.45%20RAP/ICAs/NHSs/NHS119%20Muchaulo%20Mwiba.PDF?csf=1&web=1', 'Fisher', true),
  -- NHS120: CSV had "01.11,2023" (comma); corrected to 2023-11-01
  ('NHS120', '2023-11-01', 'https://westernpower.sharepoint.com/:b:/r/sites/WPCWorking/Shared%20Documents/TEN%20Environmental%20and%20Social/E.45%20RAP/ICAs/NHSs/NHS120%20Mwananyambe%20Martin.PDF?csf=1&web=1', 'Fisher', true),
  -- NHS121: CSV had "01.11,2023" (comma); corrected to 2023-11-01
  ('NHS121', '2023-11-01', 'https://westernpower.sharepoint.com/:b:/r/sites/WPCWorking/Shared%20Documents/TEN%20Environmental%20and%20Social/E.45%20RAP/ICAs/NHSs/NHS121%20Mubiana%20Mbuto.PDF?csf=1&web=1', 'Fisher', true),
  ('NHS122', '2023-11-01', 'https://westernpower.sharepoint.com/:b:/r/sites/WPCWorking/Shared%20Documents/TEN%20Environmental%20and%20Social/E.45%20RAP/ICAs/NHSs/NHS122%20Milapo%20Victor%20Ilukena.PDF?csf=1&web=1', 'Fisher', true),
  ('NHS123', '2023-11-02', 'https://westernpower.sharepoint.com/:b:/r/sites/WPCWorking/Shared%20Documents/TEN%20Environmental%20and%20Social/E.45%20RAP/ICAs/NHSs/NHS123%20Likezo%20Nasilele.PDF?csf=1&web=1', 'Fisher', true),
  ('NHS124', '2023-11-02', 'https://westernpower.sharepoint.com/:b:/r/sites/WPCWorking/Shared%20Documents/TEN%20Environmental%20and%20Social/E.45%20RAP/ICAs/NHSs/NHS124%20Namenda%20Muchaulo.PDF?csf=1&web=1', 'Fisher', true),
  -- NHS125: CSV had "01.11,2023" (comma); corrected to 2023-11-01
  ('NHS125', '2023-11-01', 'https://westernpower.sharepoint.com/:b:/r/sites/WPCWorking/Shared%20Documents/TEN%20Environmental%20and%20Social/E.45%20RAP/ICAs/NHSs/NHS125%20Maxwel%20Mukendwa.PDF?csf=1&web=1', 'Fisher', true),
  ('NHS126', '2023-11-01', 'https://westernpower.sharepoint.com/:b:/r/sites/WPCWorking/Shared%20Documents/TEN%20Environmental%20and%20Social/E.45%20RAP/ICAs/NHSs/NHS126%20Gift%20Lubango.PDF?csf=1&web=1', 'Fisher', true),
  ('NHS127', '2023-11-06', 'https://westernpower.sharepoint.com/:b:/r/sites/WPCWorking/Shared%20Documents/TEN%20Environmental%20and%20Social/E.45%20RAP/ICAs/NHSs/NHS127%20Nalinanga%20Mwiya.PDF?csf=1&web=1', 'Fisher', true),
  ('NHS128', '2023-11-08', 'https://westernpower.sharepoint.com/:b:/r/sites/WPCWorking/Shared%20Documents/TEN%20Environmental%20and%20Social/E.45%20RAP/ICAs/NHSs/NHS128%20Kase%20Mululu.PDF?csf=1&web=1', 'Fisher', true),
  ('NHS129', '2023-11-02', 'https://westernpower.sharepoint.com/:b:/r/sites/WPCWorking/Shared%20Documents/TEN%20Environmental%20and%20Social/E.45%20RAP/ICAs/NHSs/NHS129%20Namenda%20Muyendekwa.PDF?csf=1&web=1', 'Fisher', true),
  ('NHS130', '2023-11-01', 'https://westernpower.sharepoint.com/:b:/r/sites/WPCWorking/Shared%20Documents/TEN%20Environmental%20and%20Social/E.45%20RAP/ICAs/NHSs/NHS130%20Mululu%20Mululu.PDF?csf=1&web=1', 'Fisher', true),
  ('NHS132', '2023-11-06', 'https://westernpower.sharepoint.com/:b:/r/sites/WPCWorking/Shared%20Documents/TEN%20Environmental%20and%20Social/E.45%20RAP/ICAs/NHSs/NHS132%20Matakala%20Mulomba.pdf?csf=1&web=1', 'Fisher', true),
  ('NHS133', '2023-11-06', 'https://westernpower.sharepoint.com/:b:/r/sites/WPCWorking/Shared%20Documents/TEN%20Environmental%20and%20Social/E.45%20RAP/ICAs/NHSs/NHS133%20Mabenga%20Muyumba.pdf?csf=1&web=1', 'Fisher', true),
  ('NHS134', '2023-11-02', 'https://westernpower.sharepoint.com/:b:/r/sites/WPCWorking/Shared%20Documents/TEN%20Environmental%20and%20Social/E.45%20RAP/ICAs/NHSs/NHS134%20Sitali%20Rosemary.PDF?csf=1&web=1', 'Fisher', true),
  ('NHS135', '2023-11-01', 'https://westernpower.sharepoint.com/:b:/r/sites/WPCWorking/Shared%20Documents/TEN%20Environmental%20and%20Social/E.45%20RAP/ICAs/NHSs/NHS135%20Nyambe%20Saloba.PDF?csf=1&web=1', 'Fisher', true),
  ('NHS136', '2023-11-06', 'https://westernpower.sharepoint.com/:b:/r/sites/WPCWorking/Shared%20Documents/TEN%20Environmental%20and%20Social/E.45%20RAP/ICAs/NHSs/NHS136%20Kamunika%20Kalemba.PDF?csf=1&web=1', 'Fisher', true),
  ('NHS137', '2023-11-01', 'https://westernpower.sharepoint.com/:b:/r/sites/WPCWorking/Shared%20Documents/TEN%20Environmental%20and%20Social/E.45%20RAP/ICAs/NHSs/NHS137%20Matakala%20Pelekelo.PDF?csf=1&web=1', 'Fisher', true),
  ('NHS138', '2023-11-08', 'https://westernpower.sharepoint.com/:b:/r/sites/WPCWorking/Shared%20Documents/TEN%20Environmental%20and%20Social/E.45%20RAP/ICAs/NHSs/NHS138%20Simasiku%20Imakando.PDF?csf=1&web=1', 'Fisher', true),
  ('NHS140', '2023-11-02', 'https://westernpower.sharepoint.com/:b:/r/sites/WPCWorking/Shared%20Documents/TEN%20Environmental%20and%20Social/E.45%20RAP/ICAs/NHSs/NHS140%20Mwiya%20Mubita.pdf?csf=1&web=1', 'Fisher', true),
  -- NHS141: "Mahupulo Kufakwandi.pdf" rejected (names reversed); correct order is Kufakwandi Mahupulo
  ('NHS141', '2023-11-08', 'https://westernpower.sharepoint.com/:b:/r/sites/WPCWorking/Shared%20Documents/TEN%20Environmental%20and%20Social/E.45%20RAP/ICAs/NHSs/NHS141%20Kufakwandi%20Mahupulo.PDF?csf=1&web=1', 'Fisher', true),
  ('NHS142', '2023-11-06', 'https://westernpower.sharepoint.com/:b:/r/sites/WPCWorking/Shared%20Documents/TEN%20Environmental%20and%20Social/E.45%20RAP/ICAs/NHSs/NHS142%20Sishekano%20Mukendwa.PDF?csf=1&web=1', 'Fisher', true),
  ('NHS144', '2023-11-03', 'https://westernpower.sharepoint.com/:b:/r/sites/WPCWorking/Shared%20Documents/TEN%20Environmental%20and%20Social/E.45%20RAP/ICAs/NHSs/NHS144%20Clare%20Nasilele.PDF?csf=1&web=1', 'Fisher', true),
  ('NHS145', '2023-11-08', 'https://westernpower.sharepoint.com/:b:/r/sites/WPCWorking/Shared%20Documents/TEN%20Environmental%20and%20Social/E.45%20RAP/ICAs/NHSs/NHS145%20Lubasi%20Lyambela.PDF?csf=1&web=1', 'Fisher', true),
  ('NHS146', '2023-11-02', 'https://westernpower.sharepoint.com/:b:/r/sites/WPCWorking/Shared%20Documents/TEN%20Environmental%20and%20Social/E.45%20RAP/ICAs/NHSs/NHS146%20Liswaniso%20Mwiba.PDF?csf=1&web=1', 'Fisher', true),
  -- NHS147: filename has a trailing space before extension on disk
  ('NHS147', '2023-11-01', 'https://westernpower.sharepoint.com/:b:/r/sites/WPCWorking/Shared%20Documents/TEN%20Environmental%20and%20Social/E.45%20RAP/ICAs/NHSs/NHS147%20Liswaniso%20Milapo%20.PDF?csf=1&web=1', 'Fisher', true),
  ('NHS148', '2023-10-31', 'https://westernpower.sharepoint.com/:b:/r/sites/WPCWorking/Shared%20Documents/TEN%20Environmental%20and%20Social/E.45%20RAP/ICAs/NHSs/NHS148%20Linganga%20Mubita.PDF?csf=1&web=1', 'Fisher', true),
  ('NHS149', '2023-11-02', 'https://westernpower.sharepoint.com/:b:/r/sites/WPCWorking/Shared%20Documents/TEN%20Environmental%20and%20Social/E.45%20RAP/ICAs/NHSs/NHS149%20Sinyama%20Nampewo.PDF?csf=1&web=1', 'Fisher', true),
  ('NHS150', '2023-11-02', 'https://westernpower.sharepoint.com/:b:/r/sites/WPCWorking/Shared%20Documents/TEN%20Environmental%20and%20Social/E.45%20RAP/ICAs/NHSs/NHS150%20Sumbwa%20Mulemwa.PDF?csf=1&web=1', 'Fisher', true),
  ('NHS153', '2023-11-08', 'https://westernpower.sharepoint.com/:b:/r/sites/WPCWorking/Shared%20Documents/TEN%20Environmental%20and%20Social/E.45%20RAP/ICAs/NHSs/NHS153%20Kaonde%20Malumbano.pdf?csf=1&web=1', 'Fisher', true),
  ('NHS155', '2023-11-05', 'https://westernpower.sharepoint.com/:b:/r/sites/WPCWorking/Shared%20Documents/TEN%20Environmental%20and%20Social/E.45%20RAP/ICAs/NHSs/NHS155%20Muyambango%20Maketo.PDF?csf=1&web=1', 'Fisher', true),
  -- NHS156: CSV had "01,11,2023" (commas); filename has trailing space before extension on disk
  ('NHS156', '2023-11-01', 'https://westernpower.sharepoint.com/:b:/r/sites/WPCWorking/Shared%20Documents/TEN%20Environmental%20and%20Social/E.45%20RAP/ICAs/NHSs/NHS156%20Likezo%20Mukendwa%20.PDF?csf=1&web=1', 'Fisher', true),
  -- NHS157: CSV had trailing space in date; corrected
  ('NHS157', '2023-11-01', 'https://westernpower.sharepoint.com/:b:/r/sites/WPCWorking/Shared%20Documents/TEN%20Environmental%20and%20Social/E.45%20RAP/ICAs/NHSs/NHS157%20Gorbar%20Chanda.PDF?csf=1&web=1', 'Fisher', true),
  ('NHS160', '2023-11-02', 'https://westernpower.sharepoint.com/:b:/r/sites/WPCWorking/Shared%20Documents/TEN%20Environmental%20and%20Social/E.45%20RAP/ICAs/NHSs/NHS160%20Muyumbana%20S%20Morris.PDF?csf=1&web=1', 'Fisher', true),
  ('NHS161', '2023-11-06', 'https://westernpower.sharepoint.com/:b:/r/sites/WPCWorking/Shared%20Documents/TEN%20Environmental%20and%20Social/E.45%20RAP/ICAs/NHSs/NHS161%20Kasamu%20Mabenga.PDF?csf=1&web=1', 'Fisher', true),
  ('NHS162', '2023-11-02', 'https://westernpower.sharepoint.com/:b:/r/sites/WPCWorking/Shared%20Documents/TEN%20Environmental%20and%20Social/E.45%20RAP/ICAs/NHSs/NHS162%20Namasiku%20Konga.PDF?csf=1&web=1', 'Fisher', true),
  -- NHS163: CSV had "03.11,2023" (comma); corrected to 2023-11-03
  ('NHS163', '2023-11-03', 'https://westernpower.sharepoint.com/:b:/r/sites/WPCWorking/Shared%20Documents/TEN%20Environmental%20and%20Social/E.45%20RAP/ICAs/NHSs/NHS163%20Nandila%20Milimo.PDF?csf=1&web=1', 'Fisher', true),
  ('NHS164', '2023-11-03', 'https://westernpower.sharepoint.com/:b:/r/sites/WPCWorking/Shared%20Documents/TEN%20Environmental%20and%20Social/E.45%20RAP/ICAs/NHSs/NHS164%20Anawana%20Munyungi.PDF?csf=1&web=1', 'Fisher', true),
  ('NHS165', '2023-11-03', 'https://westernpower.sharepoint.com/:b:/r/sites/WPCWorking/Shared%20Documents/TEN%20Environmental%20and%20Social/E.45%20RAP/ICAs/NHSs/NHS165%20Dorothy%20Kwalabana.PDF?csf=1&web=1', 'Fisher', true),
  ('NHS166', '2023-11-03', 'https://westernpower.sharepoint.com/:b:/r/sites/WPCWorking/Shared%20Documents/TEN%20Environmental%20and%20Social/E.45%20RAP/ICAs/NHSs/NHS166%20Paul%20Chabala.PDF?csf=1&web=1', 'Fisher', true),
  ('NHS167', '2023-11-03', 'https://westernpower.sharepoint.com/:b:/r/sites/WPCWorking/Shared%20Documents/TEN%20Environmental%20and%20Social/E.45%20RAP/ICAs/NHSs/NHS167%20Lifumbela%20Baggrey%20Buchete.PDF?csf=1&web=1', 'Fisher', true),
  ('NHS168', '2023-11-03', 'https://westernpower.sharepoint.com/:b:/r/sites/WPCWorking/Shared%20Documents/TEN%20Environmental%20and%20Social/E.45%20RAP/ICAs/NHSs/NHS168%20Flex%20Simasiku.PDF?csf=1&web=1', 'Fisher', true),
  ('NHS169', '2023-11-03', 'https://westernpower.sharepoint.com/:b:/r/sites/WPCWorking/Shared%20Documents/TEN%20Environmental%20and%20Social/E.45%20RAP/ICAs/NHSs/NHS169%20Lifumbelo%20Mutafela.PDF?csf=1&web=1', 'Fisher', true),
  ('NHS170', '2023-11-03', 'https://westernpower.sharepoint.com/:b:/r/sites/WPCWorking/Shared%20Documents/TEN%20Environmental%20and%20Social/E.45%20RAP/ICAs/NHSs/NHS170%20Mafenyeho%20Masiye.PDF?csf=1&web=1', 'Fisher', true),
  ('NHS171', '2023-11-03', 'https://westernpower.sharepoint.com/:b:/r/sites/WPCWorking/Shared%20Documents/TEN%20Environmental%20and%20Social/E.45%20RAP/ICAs/NHSs/NHS171%20Liswaniso%20Josephine.PDF?csf=1&web=1', 'Fisher', true),
  ('NHS172', '2023-11-03', 'https://westernpower.sharepoint.com/:b:/r/sites/WPCWorking/Shared%20Documents/TEN%20Environmental%20and%20Social/E.45%20RAP/ICAs/NHSs/NHS172%20Mubita%20Sitali.PDF?csf=1&web=1', 'Fisher', true),
  ('NHS173', '2023-11-07', 'https://westernpower.sharepoint.com/:b:/r/sites/WPCWorking/Shared%20Documents/TEN%20Environmental%20and%20Social/E.45%20RAP/ICAs/NHSs/NHS173%20Simasiku%20Milunga.PDF?csf=1&web=1', 'Fisher', true),
  ('NHS174', '2023-11-03', 'https://westernpower.sharepoint.com/:b:/r/sites/WPCWorking/Shared%20Documents/TEN%20Environmental%20and%20Social/E.45%20RAP/ICAs/NHSs/NHS174%20Sitali%20Mubita.PDF?csf=1&web=1', 'Fisher', true),
  ('NHS175', '2023-11-07', 'https://westernpower.sharepoint.com/:b:/r/sites/WPCWorking/Shared%20Documents/TEN%20Environmental%20and%20Social/E.45%20RAP/ICAs/NHSs/NHS175%20Kayombe%20Simasiku.PDF?csf=1&web=1', 'Fisher', true),
  ('NHS176', '2023-11-03', 'https://westernpower.sharepoint.com/:b:/r/sites/WPCWorking/Shared%20Documents/TEN%20Environmental%20and%20Social/E.45%20RAP/ICAs/NHSs/NHS176%20Sepiso%20Munyangwe.PDF?csf=1&web=1', 'Fisher', true),
  ('NHS177', '2023-11-07', 'https://westernpower.sharepoint.com/:b:/r/sites/WPCWorking/Shared%20Documents/TEN%20Environmental%20and%20Social/E.45%20RAP/ICAs/NHSs/NHS177%20Joseph%20Muyunda.PDF?csf=1&web=1', 'Fisher', true),
  ('NHS178', '2023-11-03', 'https://westernpower.sharepoint.com/:b:/r/sites/WPCWorking/Shared%20Documents/TEN%20Environmental%20and%20Social/E.45%20RAP/ICAs/NHSs/NHS178%20Elizabeth%20Mwinke.PDF?csf=1&web=1', 'Fisher', true),
  -- NHS179: V2 exists (signed 2026-02-05); original marked not current
  ('NHS179', '2023-11-03', 'https://westernpower.sharepoint.com/:b:/r/sites/WPCWorking/Shared%20Documents/TEN%20Environmental%20and%20Social/E.45%20RAP/ICAs/NHSs/NHS179%20Harriet%20Sambano.pdf?csf=1&web=1', 'Fisher', false),
  ('NHS179', '2026-02-05', 'https://westernpower.sharepoint.com/:b:/r/sites/WPCWorking/Shared%20Documents/TEN%20Environmental%20and%20Social/E.45%20RAP/ICAs/NHSs/NHS179%20Harriet%20Sambano%20V2%2020260205.pdf?csf=1&web=1', 'Fisher', true),
  ('NHS180', '2023-11-03', 'https://westernpower.sharepoint.com/:b:/r/sites/WPCWorking/Shared%20Documents/TEN%20Environmental%20and%20Social/E.45%20RAP/ICAs/NHSs/NHS180%20Mubita%20Mubano.PDF?csf=1&web=1', 'Fisher', true),
  ('NHS181', '2023-11-07', 'https://westernpower.sharepoint.com/:b:/r/sites/WPCWorking/Shared%20Documents/TEN%20Environmental%20and%20Social/E.45%20RAP/ICAs/NHSs/NHS181%20Laele%20Masiye.PDF?csf=1&web=1', 'Fisher', true),
  ('NHS182', '2023-11-03', 'https://westernpower.sharepoint.com/:b:/r/sites/WPCWorking/Shared%20Documents/TEN%20Environmental%20and%20Social/E.45%20RAP/ICAs/NHSs/NHS182%20Petuho%20Mululu.PDF?csf=1&web=1', 'Fisher', true),
  ('NHS183', '2023-11-03', 'https://westernpower.sharepoint.com/:b:/r/sites/WPCWorking/Shared%20Documents/TEN%20Environmental%20and%20Social/E.45%20RAP/ICAs/NHSs/NHS183%20Chibeya%20Grace.PDF?csf=1&web=1', 'Fisher', true),
  ('NHS184', '2023-11-07', 'https://westernpower.sharepoint.com/:b:/r/sites/WPCWorking/Shared%20Documents/TEN%20Environmental%20and%20Social/E.45%20RAP/ICAs/NHSs/NHS184%20Musungu%20Musiyalike.PDF?csf=1&web=1', 'Fisher', true),
  ('NHS185', '2023-11-03', 'https://westernpower.sharepoint.com/:b:/r/sites/WPCWorking/Shared%20Documents/TEN%20Environmental%20and%20Social/E.45%20RAP/ICAs/NHSs/NHS185%20Simasiku%20Pelekelo.PDF?csf=1&web=1', 'Fisher', true),
  -- NHS186: CSV had "07.11,2023" (comma); corrected to 2023-11-07
  ('NHS186', '2023-11-07', 'https://westernpower.sharepoint.com/:b:/r/sites/WPCWorking/Shared%20Documents/TEN%20Environmental%20and%20Social/E.45%20RAP/ICAs/NHSs/NHS186%20Malwalo%20Chrispin.PDF?csf=1&web=1', 'Fisher', true),
  ('NHS187', '2023-11-03', 'https://westernpower.sharepoint.com/:b:/r/sites/WPCWorking/Shared%20Documents/TEN%20Environmental%20and%20Social/E.45%20RAP/ICAs/NHSs/NHS187%20Sitali%20Sitali.PDF?csf=1&web=1', 'Fisher', true),
  ('NHS188', '2023-11-03', 'https://westernpower.sharepoint.com/:b:/r/sites/WPCWorking/Shared%20Documents/TEN%20Environmental%20and%20Social/E.45%20RAP/ICAs/NHSs/NHS188%20Musiyalela%20Maimbolwa.PDF?csf=1&web=1', 'Fisher', true),
  ('NHS189', '2023-11-03', 'https://westernpower.sharepoint.com/:b:/r/sites/WPCWorking/Shared%20Documents/TEN%20Environmental%20and%20Social/E.45%20RAP/ICAs/NHSs/NHS189%20Mwendabai%20Sawabi.PDF?csf=1&web=1', 'Fisher', true),
  ('NHS190', '2023-11-03', 'https://westernpower.sharepoint.com/:b:/r/sites/WPCWorking/Shared%20Documents/TEN%20Environmental%20and%20Social/E.45%20RAP/ICAs/NHSs/NHS190%20Mwabafu%20Maswabi.PDF?csf=1&web=1', 'Fisher', true),
  ('NHS192', '2023-11-03', 'https://westernpower.sharepoint.com/:b:/r/sites/WPCWorking/Shared%20Documents/TEN%20Environmental%20and%20Social/E.45%20RAP/ICAs/NHSs/NHS192%20Mukubesa%20Munalula.PDF?csf=1&web=1', 'Fisher', true),
  ('NHS193', '2023-11-03', 'https://westernpower.sharepoint.com/:b:/r/sites/WPCWorking/Shared%20Documents/TEN%20Environmental%20and%20Social/E.45%20RAP/ICAs/NHSs/NHS193%20Sianga%20Mutendwa.PDF?csf=1&web=1', 'Fisher', true),
  ('NHS194', '2023-11-03', 'https://westernpower.sharepoint.com/:b:/r/sites/WPCWorking/Shared%20Documents/TEN%20Environmental%20and%20Social/E.45%20RAP/ICAs/NHSs/NHS194%20Nakubiana%20Masule.PDF?csf=1&web=1', 'Fisher', true),
  ('NHS195', '2023-11-03', 'https://westernpower.sharepoint.com/:b:/r/sites/WPCWorking/Shared%20Documents/TEN%20Environmental%20and%20Social/E.45%20RAP/ICAs/NHSs/NHS195%20Muyunda%20Mwiba.PDF?csf=1&web=1', 'Fisher', true),
  -- NHS196: CSV had "31.11.2023" (November has 30 days); corrected to 2023-11-30
  ('NHS196', '2023-11-30', 'https://westernpower.sharepoint.com/:b:/r/sites/WPCWorking/Shared%20Documents/TEN%20Environmental%20and%20Social/E.45%20RAP/ICAs/NHSs/NHS196%20Imasiku%20Kwalabana.pdf?csf=1&web=1', 'Fisher', true),
  -- NHS197: CSV had "07.11,2023" (comma); corrected to 2023-11-07
  ('NHS197', '2023-11-07', 'https://westernpower.sharepoint.com/:b:/r/sites/WPCWorking/Shared%20Documents/TEN%20Environmental%20and%20Social/E.45%20RAP/ICAs/NHSs/NHS197%20Kabati%20Kabati.PDF?csf=1&web=1', 'Fisher', true),
  ('NHS198', '2023-11-07', 'https://westernpower.sharepoint.com/:b:/r/sites/WPCWorking/Shared%20Documents/TEN%20Environmental%20and%20Social/E.45%20RAP/ICAs/NHSs/NHS198%20Mukwamandi%20Malindi.PDF?csf=1&web=1', 'Fisher', true),
  -- NHS200: CSV had "31,10.2023" (comma); corrected to 2023-10-31
  ('NHS200', '2023-10-31', 'https://westernpower.sharepoint.com/:b:/r/sites/WPCWorking/Shared%20Documents/TEN%20Environmental%20and%20Social/E.45%20RAP/ICAs/NHSs/NHS200%20Mwangala%20Malumo.PDF?csf=1&web=1', 'Fisher', true),
  ('NHS201', '2023-10-31', 'https://westernpower.sharepoint.com/:b:/r/sites/WPCWorking/Shared%20Documents/TEN%20Environmental%20and%20Social/E.45%20RAP/ICAs/NHSs/NHS201%20Pelekelo%20Mwananyande.PDF?csf=1&web=1', 'Fisher', true),
  ('NHS202', '2023-11-02', 'https://westernpower.sharepoint.com/:b:/r/sites/WPCWorking/Shared%20Documents/TEN%20Environmental%20and%20Social/E.45%20RAP/ICAs/NHSs/NHS202%20Mutoiwa%20Likezo.PDF?csf=1&web=1', 'Fisher', true),
  ('NHS203', '2023-11-04', 'https://westernpower.sharepoint.com/:b:/r/sites/WPCWorking/Shared%20Documents/TEN%20Environmental%20and%20Social/E.45%20RAP/ICAs/NHSs/NHS203%20Situmbeko%20Kusukuluka.PDF?csf=1&web=1', 'Fisher', true),
  -- NHS204: CSV had "07.11,2023" (comma); corrected to 2023-11-07
  ('NHS204', '2023-11-07', 'https://westernpower.sharepoint.com/:b:/r/sites/WPCWorking/Shared%20Documents/TEN%20Environmental%20and%20Social/E.45%20RAP/ICAs/NHSs/NHS204%20Mubita%20Liswani.PDF?csf=1&web=1', 'Fisher', true),
  ('NHSU100', '2023-11-06', 'https://westernpower.sharepoint.com/:b:/r/sites/WPCWorking/Shared%20Documents/TEN%20Environmental%20and%20Social/E.45%20RAP/ICAs/NHSs/NHSU100%20Kabika%20Kalemba.PDF?csf=1&web=1', 'Fisher', true),
  ('NHSU101', '2023-11-06', 'https://westernpower.sharepoint.com/:b:/r/sites/WPCWorking/Shared%20Documents/TEN%20Environmental%20and%20Social/E.45%20RAP/ICAs/NHSs/NHSU101%20Katambo%20Lutangu.PDF?csf=1&web=1', 'Fisher', true),
  ('NHSU103', '2023-11-03', 'https://westernpower.sharepoint.com/:b:/r/sites/WPCWorking/Shared%20Documents/TEN%20Environmental%20and%20Social/E.45%20RAP/ICAs/NHSs/NHSU103%20Limpo%20Sepiso.PDF?csf=1&web=1', 'Fisher', true),
  ('NHSU104', '2023-11-03', 'https://westernpower.sharepoint.com/:b:/r/sites/WPCWorking/Shared%20Documents/TEN%20Environmental%20and%20Social/E.45%20RAP/ICAs/NHSs/NHSU104%20Liswaniso%20Mebelo.PDF?csf=1&web=1', 'Fisher', true),
  ('NHSU105', '2023-11-06', 'https://westernpower.sharepoint.com/:b:/r/sites/WPCWorking/Shared%20Documents/TEN%20Environmental%20and%20Social/E.45%20RAP/ICAs/NHSs/NHSU105%20Liywali%20Kabika.PDF?csf=1&web=1', 'Fisher', true),
  ('NHSU106', '2023-11-03', 'https://westernpower.sharepoint.com/:b:/r/sites/WPCWorking/Shared%20Documents/TEN%20Environmental%20and%20Social/E.45%20RAP/ICAs/NHSs/NHSU106%20Luyanga%20Naini.PDF?csf=1&web=1', 'Fisher', true),
  ('NHSU107', '2023-11-03', 'https://westernpower.sharepoint.com/:b:/r/sites/WPCWorking/Shared%20Documents/TEN%20Environmental%20and%20Social/E.45%20RAP/ICAs/NHSs/NHSU107%20Mulobela%20Lipilae.PDF?csf=1&web=1', 'Fisher', true),
  ('NHSU108', '2023-11-07', 'https://westernpower.sharepoint.com/:b:/r/sites/WPCWorking/Shared%20Documents/TEN%20Environmental%20and%20Social/E.45%20RAP/ICAs/NHSs/NHSU108%20Maswabi%20Lutuzwi.PDF?csf=1&web=1', 'Fisher', true),
  ('NHSU116', '2023-11-01', 'https://westernpower.sharepoint.com/:b:/r/sites/WPCWorking/Shared%20Documents/TEN%20Environmental%20and%20Social/E.45%20RAP/ICAs/NHSs/NHSU116%20Muyendekwa%20F%20Mabuku.PDF?csf=1&web=1', 'Fisher', true),
  ('NHSU117', '2023-11-06', 'https://westernpower.sharepoint.com/:b:/r/sites/WPCWorking/Shared%20Documents/TEN%20Environmental%20and%20Social/E.45%20RAP/ICAs/NHSs/NHSU117%20Muyendekwa%20Liyali.PDF?csf=1&web=1', 'Fisher', true),
  ('NHSU118', '2023-11-01', 'https://westernpower.sharepoint.com/:b:/r/sites/WPCWorking/Shared%20Documents/TEN%20Environmental%20and%20Social/E.45%20RAP/ICAs/NHSs/NHSU118%20Mulomba%20Sikota.PDF?csf=1&web=1', 'Fisher', true),
  ('NHSU121', '2023-11-07', 'https://westernpower.sharepoint.com/:b:/r/sites/WPCWorking/Shared%20Documents/TEN%20Environmental%20and%20Social/E.45%20RAP/ICAs/NHSs/NHSU121%20Imakando%20Kasuka.PDF?csf=1&web=1', 'Fisher', true),
  ('NHSU122', '2023-11-07', 'https://westernpower.sharepoint.com/:b:/r/sites/WPCWorking/Shared%20Documents/TEN%20Environmental%20and%20Social/E.45%20RAP/ICAs/NHSs/NHSU122%20Akufuna%20Nalumango.PDF?csf=1&web=1', 'Fisher', true),
  ('NHSU128', '2023-11-08', 'https://westernpower.sharepoint.com/:b:/r/sites/WPCWorking/Shared%20Documents/TEN%20Environmental%20and%20Social/E.45%20RAP/ICAs/NHSs/NHSU128%20Mabumbo%20Minyoi.PDF?csf=1&web=1', 'Fisher', true),
  ('NHSU131', '2023-11-04', 'https://westernpower.sharepoint.com/:b:/r/sites/WPCWorking/Shared%20Documents/TEN%20Environmental%20and%20Social/E.45%20RAP/ICAs/NHSs/NHSU131%20Mate%20Sitali.PDF?csf=1&web=1', 'Fisher', true),
  ('NHSU132', '2023-11-04', 'https://westernpower.sharepoint.com/:b:/r/sites/WPCWorking/Shared%20Documents/TEN%20Environmental%20and%20Social/E.45%20RAP/ICAs/NHSs/NHSU132%20Mubita%20Pango.PDF?csf=1&web=1', 'Fisher', true)
;

commit;
