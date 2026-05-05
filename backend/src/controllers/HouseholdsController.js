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
  notes: 'Notes',
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
  async summary (req, res) {
    Common.debug(req, 'summary')

    try {
      const summary = {}

      // Add a count of total households
      const totalHouseholdsResult = await Knex('v_households').count('pah as count').first()
      summary.totalHouseholds = parseInt(totalHouseholdsResult.count) || 0

      // Add a count of vulnerable households
      const vulnerableHouseholdsResult = await Knex('v_households').where('vulnerable', true).count('pah as count').first()
      summary.vulnerableHouseholds = parseInt(vulnerableHouseholdsResult.count) || 0

      // Add a count of physically displaced households
      const displacedHouseholdsResult = await Knex('v_households').where('physically_displaced', true).count('pah as count').first()
      summary.physicallyDisplacedHouseholds = parseInt(displacedHouseholdsResult.count) || 0

      // Add a count of households with no ICA required
      const noICAHouseholdsResult = await Knex('v_households').where('no_ica_required', true).count('pah as count').first()
      summary.noICARequiredHouseholds = parseInt(noICAHouseholdsResult.count) || 0

      // Add a count of non-affected households
      const nonAffectedHouseholdsResult = await Knex('v_households').where('nonaffected', true).count('pah as count').first()
      summary.nonAffectedHouseholds = parseInt(nonAffectedHouseholdsResult.count) || 0

      // Add a count of signed households
      const signedHouseholdsResult = await Knex('v_households').whereNotNull('date_signed').count('pah as count').first()
      summary.signedHouseholds = parseInt(signedHouseholdsResult.count) || 0

      summary.ICARequiredHouseholds = summary.totalHouseholds - summary.noICARequiredHouseholds
      summary.unsignedHouseholds = summary.totalHouseholds - summary.signedHouseholds - summary.noICARequiredHouseholds

      // Add a count of households with follow-up flag
      const followUpHouseholdsResult = await Knex('v_households').where('household_followup_flag', true).count('pah as count').first()
      summary.followUpFlagHouseholds = parseInt(followUpHouseholdsResult.count) || 0

      // Add a count of households with landholding only
      const landholdingOnlyHouseholdsResult = await Knex('v_households').where('landholding_only', true).count('pah as count').first()
      summary.landholdingOnlyHouseholds = parseInt(landholdingOnlyHouseholdsResult.count) || 0

      // Add a count of households the require a new ica
      const newICAHouseholdsResult = await Knex('v_households').where('new_ica_required', true).count('pah as count').first()
      summary.newICARequiredHouseholds = parseInt(newICAHouseholdsResult.count) || 0

      // Add a count of households that have replacement households (replacement_structures_count>0)
      const replacementHouseholdsResult = await Knex('v_households').where('replacement_structures_count', '>', 0).count('pah as count').first()
      summary.replacementHouseholds = parseInt(replacementHouseholdsResult.count) || 0

      // Add a count of households that have replacement land (replacement_land_area>0)
      const replacementLandHouseholdsResult = await Knex('v_households').where('replacement_land_area', '>', 0).count('pah as count').first()
      summary.replacementLandHouseholds = parseInt(replacementLandHouseholdsResult.count) || 0

      // Add a sum of structures
      const structuresResult = await Knex('v_households').sum('structures_count as total').first()
      summary.totalStructures = parseFloat(structuresResult.total) || 0

      // Add a sum of primary structures
      const primaryStructuresResult = await Knex('v_households').sum('primary_structures_count as total').first()
      summary.totalPrimaryStructures = parseFloat(primaryStructuresResult.total) || 0

      // Add a sum of secondary structures
      const secondaryStructuresResult = await Knex('v_households').sum('secondary_structures_count as total').first()
      summary.totalSecondaryStructures = parseFloat(secondaryStructuresResult.total) || 0

      // Add a sum of primary structures compensation value
      const primaryStructuresCompResult = await Knex('v_household_compensation').sum('primary_structures_compensation_value as total').first()
      summary.totalPrimaryStructuresCompensation = parseFloat(primaryStructuresCompResult.total) || 0

      // Add a sum of secondary structures compensation value
      const secondaryStructuresCompResult = await Knex('v_household_compensation').sum('secondary_structures_compensation_value as total').first()
      summary.totalSecondaryStructuresCompensation = parseFloat(secondaryStructuresCompResult.total) || 0

      // Add a sum of allowances
      const allowancesResult = await Knex('v_household_compensation').sum('allowance_total as total').first()
      summary.totalAllowances = parseFloat(allowancesResult.total) || 0

      // Add a sum of lease costs
      const leaseCostsResult = await Knex('v_household_compensation').sum('lease_cost_total as total').first()
      summary.totalLeaseCosts = parseFloat(leaseCostsResult.total) || 0

      // Add a sum of land compensation value
      const landCompResult = await Knex('v_household_compensation').sum('land_compensation_value as total').first()
      summary.totalLandCompensation = parseFloat(landCompResult.total) || 0

      // Add a sum of trees compensation
      const treesCompResult = await Knex('v_household_compensation').sum('trees_compensation as total').first()
      summary.totalTreesCompensation = parseFloat(treesCompResult.total) || 0

      // Add a sum of crops value
      const cropsValueResult = await Knex('v_household_compensation').sum('crop_value as total').first()
      summary.totalCropCompensation = parseFloat(cropsValueResult.total) || 0

      // Add a total compensation value
      const totalCompResult = await Knex('v_household_compensation').sum('total_cash_compensation as total').first()
      summary.totalCompensation = parseFloat(totalCompResult.total) || 0

      res.send(summary)
    } catch (err) {
      Common.error(req, 'summary', err)
      res.status(500).send({ error: 'an error has occurred trying to fetch households summary: ' + err })
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
}
