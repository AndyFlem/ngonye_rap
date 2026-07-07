const Knex = require('../services/db')
const Common = require('./CommonDebug')('Households')

const EXPORT_COLUMNS = {
  pah: 'PAH',
  firstname: 'First Name',
  middlename: 'Middle Name',
  lastname: 'Last Name',
  household_head: 'Household Head',
  household_head_fullname: 'Household Head (Full Name)',
  nrc: 'NRC',
  contact: 'Contact',
  cosignatory: 'Cosignatory',
  cosignatory_nrc: 'Cosignatory NRC',
  cosignatory_contact: 'Cosignatory Contact',
  linked_pah: 'Linked PAH',
  landholding_only: 'Landholding Only',
  village: 'Village',
  vulnerable: 'Vulnerable',
  nonaffected: 'Non-Affected',
  physically_displaced: 'Physically Displaced',
  silumesii: 'Silumesii',
  no_ica_required: 'No ICA Required',
  new_ica_required: 'New ICA Required',
  date_signed: 'ICA Date Signed',
  ica_link: 'ICA Link',
  household_followup_flag: 'Follow-Up Flag',
  icaoption_primary_structure: 'ICA Option: Primary Structure',
  icaoption_structure_location: 'ICA Option: Structure Location',
  icaoption_landholding: 'ICA Option: Landholding',
  icaoption_dryland: 'ICA Option: Dryland',
  icaoption_garden: 'ICA Option: Garden',
  icaoption_transport: 'ICA Option: Transport',
  allowance_disturbance: 'Allowance: Disturbance',
  allowance_transport: 'Allowance: Transport',
  allowance_transitional: 'Allowance: Transitional',
  allowance_business: 'Allowance: Business',
  allowance_rental: 'Allowance: Rental',
  allowance_landprep: 'Allowance: Land Prep',
  allowance_total: 'Allowance: Total',
  lr_agricultural: 'LR: Agricultural',
  lr_livestock: 'LR: Livestock',
  lr_water: 'LR: Water',
  lr_fisheries: 'LR: Fisheries',
  lr_reedbeds: 'LR: Reedbeds',
  lr_agricultureinputs: 'LR: Agriculture Inputs',
  structures_count: 'Structures Count',
  primary_structures_count: 'Primary Structures Count',
  secondary_structures_count: 'Secondary Structures Count',
  replacement_structures_count: 'Replacement Structures Count',
  primary_structures_compensation_value: 'Primary Structures Compensation',
  secondary_structures_compensation_value: 'Secondary Structures Compensation',
  replacement_structures_value: 'Replacement Structures Value',
  permanent_land_area: 'Permanent Land Area',
  permanent_land_value: 'Permanent Land Value',
  land_compensation_value: 'Land Compensation Value',
  replacement_land_area: 'Replacement Land Area',
  lease_cost_total: 'Lease Cost Total',
  trees_compensation: 'Trees Compensation',
  replacement_saplings: 'Replacement Saplings',
  crop_size: 'Crop Size',
  crop_value: 'Crop Value',
}

function buildSearchParams (defn) {
  const params = []
  if (defn.household_head) { params.push(`p_household_head=> '${defn.household_head.replace(/'/g, "''")}'`) }
  if (defn.pah) { params.push(`p_pah=> '${defn.pah.replace(/'/g, "''")}'`) }
  if (defn.vulnerable !== undefined && defn.vulnerable !== null) { params.push(`p_vulnerable=> ${defn.vulnerable}`) }
  if (defn.nonaffected !== undefined && defn.nonaffected !== null) { params.push(`p_nonaffected=> ${defn.nonaffected}`) }
  if (defn.landholding_only !== undefined && defn.landholding_only !== null) { params.push(`p_landholding_only=> ${defn.landholding_only}`) }
  if (defn.silumesii !== undefined && defn.silumesii !== null) { params.push(`p_silumesii=> ${defn.silumesii}`) }
  if (defn.new_ica_required !== undefined && defn.new_ica_required !== null) { params.push(`p_new_ica_required=> ${defn.new_ica_required}`) }
  if (defn.followup_flag !== undefined && defn.followup_flag !== null) { params.push(`p_followup_flag=> ${defn.followup_flag}`) }
  if (defn.physically_displaced !== undefined && defn.physically_displaced !== null) { params.push(`p_physically_displaced=> ${defn.physically_displaced}`) }
  if (defn.no_ica_required !== undefined && defn.no_ica_required !== null) { params.push(`p_no_ica_required=> ${defn.no_ica_required}`) }
  if (defn.icasigned !== undefined && defn.icasigned !== null) { params.push(`p_icasigned=> ${defn.icasigned}`) }
  if (defn.nrc) { params.push(`p_nrc=> '${defn.nrc.replace(/'/g, "''")}'`) }
  if (defn.village_id && defn.village_id !== 'all') {
    const villageId = parseInt(defn.village_id)
    if (!isNaN(villageId)) { params.push(`p_village_id=> ${villageId}`) }
  }
  const icaOptionFields = ['icaoption_primary_structure', 'icaoption_structure_location', 'icaoption_landholding', 'icaoption_dryland', 'icaoption_garden', 'icaoption_transport']
  for (const field of icaOptionFields) {
    if (defn[field]) { params.push(`p_${field}=> '${defn[field].replace(/'/g, "''")}'`) }
  }
  if (defn.has_replacement_structures !== undefined && defn.has_replacement_structures !== null) { params.push(`p_has_replacement_structures=> ${defn.has_replacement_structures}`) }
  if (defn.has_replacement_land !== undefined && defn.has_replacement_land !== null) { params.push(`p_has_replacement_land=> ${defn.has_replacement_land}`) }
  if (defn.has_protected !== undefined && defn.has_protected !== null) { params.push(`p_has_protected=> ${defn.has_protected}`) }
  if (defn.survey_complete !== undefined && defn.survey_complete !== null) { params.push(`p_survey_complete=> ${defn.survey_complete}`) }
  if (defn.has_current_grievance !== undefined && defn.has_current_grievance !== null) { params.push(`p_has_current_grievance=> ${defn.has_current_grievance}`) }
  if (defn.has_multiple_icas !== undefined && defn.has_multiple_icas !== null) { params.push(`p_has_multiple_icas=> ${defn.has_multiple_icas}`) }
  if (defn.has_linked_fisher !== undefined && defn.has_linked_fisher !== null) { params.push(`p_has_linked_fisher=> ${defn.has_linked_fisher}`) }
  if (defn.has_notes !== undefined && defn.has_notes !== null) { params.push(`p_has_notes=> ${defn.has_notes}`) }
  if (defn.is_duplicate !== undefined && defn.is_duplicate !== null) { params.push(`p_is_duplicate=> ${defn.is_duplicate}`) }
  return params
}
function csvEscape (val) {
  if (val === null || val === undefined) return ''
  const s = String(val)
  if (s.includes(',') || s.includes('"') || s.includes('\n') || s.includes('\r')) {
    return '"' + s.replace(/"/g, '""') + '"'
  }
  return s
}

module.exports = {
  async patch (req, res) {
    Common.debug(req, 'patch')
    const pah = (req.params.pah || '').trim().slice(0, 120)
    if (!pah) return res.status(400).send({ error: 'pah is required' })

    const allowed = {
      village_id: 'village_id',
      household_followup_flag: 'followup_flag',
      new_ica_required: 'new_ica_required',
      duplicate_pah: 'duplicate_pah',
      icaoption_landholding: 'icaoption_landholding',
      icaoption_dryland: 'icaoption_dryland',
      icaoption_garden: 'icaoption_garden'
    }
    const fields = {}
    for (const [bodyKey, colName] of Object.entries(allowed)) {
      if (bodyKey in req.body) fields[colName] = req.body[bodyKey]
    }
    if (Object.keys(fields).length === 0) {
      return res.status(400).send({ error: 'no valid fields provided' })
    }

    try {
      const count = await Knex('households').where('pah', pah).update(fields)
      if (!count) return res.status(404).send({ error: 'household not found' })

      if ('new_ica_required' in req.body) {
        await Knex('notes').insert({
          user_id: req.userId,
          pah,
          note: `New ICA required set to ${req.body.new_ica_required}`,
          created_at: Knex.fn.now()
        })
      }

      return res.send({ success: true })
    } catch (err) {
      Common.error(req, 'patch', err)
      return res.status(500).send({ error: 'an error has occurred trying to update household: ' + err })
    }
  },
  async search (req, res) {
    Common.debug(req, 'search')
    try {
      const params = buildSearchParams(req.body)
      let qry = 'SELECT pah FROM public.a_households_search(' + params.join() + ')'
      if (req.body.orderby) { qry += ' ORDER BY ' + req.body.orderby }
      Common.debug(null, 'doSearch', 'Query: ' + qry)
      const rws = await Knex.raw(qry)
      return res.send(rws.rows)
    } catch (err) {
      Common.error(req, 'search', err)
      return res.status(500).send({ error: 'an error has occured trying to search the households: ' + err })
    }
  },
  async exportSearch (req, res) {
    Common.debug(req, 'exportSearch')
    try {
      const params = buildSearchParams(req.body)
      const searchCall = 'public.a_households_search(' + params.join() + ')'
      const qry = `SELECT h.* FROM v_households h WHERE h.pah IN (SELECT pah FROM ${searchCall}) ORDER BY h.pah`
      Common.debug(null, 'exportSearch', 'Query: ' + qry)
      const rws = await Knex.raw(qry)
      const rows = rws.rows

      const fields = Object.keys(EXPORT_COLUMNS)
      const header = fields.map(f => EXPORT_COLUMNS[f]).join(',')
      const lines = rows.map(row =>
        fields.map(f => csvEscape(row[f])).join(',')
      )
      const csv = [header, ...lines].join('\r\n')

      res.setHeader('Content-Type', 'text/csv')
      res.setHeader('Content-Disposition', 'attachment; filename="households.csv"')
      return res.send(csv)
    } catch (err) {
      Common.error(req, 'exportSearch', err)
      return res.status(500).send({ error: 'an error has occurred trying to export households: ' + err })
    }
  },
  async show (req, res) {
    Common.debug(req, 'show')

    const pah = (req.params.pah || '').trim().slice(0, 120)

    if (!pah) {
      return res.status(400).send({ error: 'pah is required' })
    }

    try {
      const household = await Knex('v_households')
        .where({ pah })
        .first()

      if (!household) {
        return res.status(404).send({ error: 'household not found' })
      }

      const comp = await Knex('v_household_compensation')
        .where({ pah })
        .first()
      household.compensation = comp || null

      const landComp = await Knex('v_household_land_compensation')
        .where({ pah })
        .orderBy('acquisition_class')
        .orderBy('rate_acquisition_class')
      household.land_compensation = landComp || []

      return res.send(household)
    } catch (err) {
      Common.error(req, 'show', err)
      return res.status(500).send({ error: 'an error has occurred trying to fetch the household: ' + err })
    }
  },
  async indexParcels (req, res) {
    Common.debug(req, 'indexParcels')
    const pah = (req.params.pah || '').trim().slice(0, 120)

    if (!pah) {
      return res.status(400).send({ error: 'pah is required' })
    }

    try {
      const parcels = await Knex('v_land_parcels')
        .where({ pah })

      // For each parcel load associated v_land_assets rows
      for (const parcel of parcels) {
        const assets = await Knex('v_land_assets')
          .where({ land_parcel_id: parcel.land_parcel_id })
        parcel.assets = assets
      }

      return res.send(parcels)
    } catch (err) {
      Common.error(req, 'indexParcels', err)
      return res.status(500).send({ error: 'an error has occurred trying to fetch the parcels for the household: ' + err })
    }
  },
  async indexStructures (req, res) {
    Common.debug(req, 'indexStructures')
    const pah = (req.params.pah || '').trim().slice(0, 120)

    if (!pah) {
      return res.status(400).send({ error: 'pah is required' })
    }

    try {
      const structures = await Knex('v_structures')
        .where({ pah })

      return res.send(structures)
    } catch (err) {
      Common.error(req, 'indexStructures', err)
      return res.status(500).send({ error: 'an error has occurred trying to fetch the structures for the household: ' + err })
    }
  },
  async indexIcaOptions (req, res) {
    Common.debug(req, 'indexIcaOptions')
    const fields = ['icaoption_primary_structure', 'icaoption_structure_location', 'icaoption_landholding', 'icaoption_dryland', 'icaoption_garden', 'icaoption_transport']
    try {
      const result = {}
      for (const field of fields) {
        const rows = await Knex('v_households').distinct(field).whereNotNull(field).orderBy(field)
        result[field] = rows.map(r => r[field])
      }
      return res.send(result)
    } catch (err) {
      Common.error(req, 'indexIcaOptions', err)
      return res.status(500).send({ error: 'an error has occurred fetching ICA options: ' + err })
    }
  },
  async indexTrees (req, res) {
    Common.debug(req, 'indexTrees')
    const pah = (req.params.pah || '').trim().slice(0, 120)
    
    if (!pah) {
      return res.status(400).send({ error: 'pah is required' })
    }
    try {
      const trees = await Knex('v_trees_summary')
        .where({ pah })

      return res.send(trees)
    } catch (err) {
      Common.error(req, 'indexTrees', err)
      return res.status(500).send({ error: 'an error has occurred trying to fetch the trees for the household: ' + err })
    }
  },
  async indexCrops (req, res) {
    Common.debug(req, 'indexCrops')
    const pah = (req.params.pah || '').trim().slice(0, 120)
    
    if (!pah) {
      return res.status(400).send({ error: 'pah is required' })
    }
    try {
      const crops = await Knex('v_crops')
        .where({ pah })

      return res.send(crops)
    } catch (err) {
      Common.error(req, 'indexCrops', err)
      return res.status(500).send({ error: 'an error has occurred trying to fetch the crops for the household: ' + err })
    }
  },
  async showSurvey (req, res) {
    Common.debug(req, 'showSurvey')
    const pah = (req.params.pah || '').trim().slice(0, 120)

    if (!pah) {
      return res.status(400).send({ error: 'pah is required' })
    }
    
    try {
      const survey = await Knex('households_survey')
        .where({ pah })
        .first()
      return res.send(survey)
    } catch (err) {
      Common.error(req, 'showSurvey', err)
      return res.status(500).send({ error: 'an error has occurred trying to fetch the survey for the household: ' + err })
    }
  },

}
