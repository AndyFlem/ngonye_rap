const Knex = require('../services/db')
const Common = require('./CommonDebug')('RAP')

module.exports = {
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

      // Add a count of households that are silumesii
      const silumesiiHouseholdsResult = await Knex('v_households').where('silumesii', true).count('pah as count').first()
      summary.silumesiiHouseholds = parseInt(silumesiiHouseholdsResult.count) || 0

      // Add a count of households that have replacement households (replacement_structures_count>0)
      const replacementHouseholdsResult = await Knex('v_households').where('replacement_structures_count', '>', 0).count('pah as count').first()
      summary.replacementHouseholds = parseInt(replacementHouseholdsResult.count) || 0

      // Add a count of households that have replacement land (replacement_land_area>0)
      const replacementLandHouseholdsResult = await Knex('v_households').where('replacement_land_area', '>', 0).count('pah as count').first()
      summary.replacementLandHouseholds = parseInt(replacementLandHouseholdsResult.count) || 0

      // Add a count of fishers
      const fishersCountResult = await Knex('v_fishers').count('nhs as count').first()
      summary.fishers = parseInt(fishersCountResult.count) || 0

      // Add a count of fishers with signed agreements
      const signedFishersCountResult = await Knex('v_fishers').whereNotNull('date_signed').count('nhs as count').first()
      summary.signedFishers = parseInt(signedFishersCountResult.count) || 0
      summary.unsignedFishers = summary.fishers - summary.signedFishers

      // Add a count of fishers with new_ica_required flag
      const newICAFishersCountResult = await Knex('v_fishers').where('new_ica_required', true).count('nhs as count').first()
      summary.newICAFishers = parseInt(newICAFishersCountResult.count) || 0

      // Add a sum of fisher site_compensation
      const fisherCompResult = await Knex('v_fishers').sum('site_compensation as total').first()
      summary.fisherSiteCompensation = parseFloat(fisherCompResult.total) || 0

      // Add a sum of fisher transitional_allowance
      const fisherTransAllowanceResult = await Knex('v_fishers').sum('transitional_allowance as total').first()
      summary.fisherTransitionalAllowance = parseFloat(fisherTransAllowanceResult.total) || 0

      // Add a sum of fisher total_compensation
      const fisherTotalCompResult = await Knex('v_fishers').sum('total_compensation as total').first()
      summary.fisherTotalCompensation = parseFloat(fisherTotalCompResult.total) || 0 

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

      // Add a count of surveys
      const surveysResult = await Knex('households_survey').count('pah as count').first()
      summary.totalSurveys = parseInt(surveysResult.count) || 0

      // Add a count of people
      const peopleResult = await Knex('v_person').count('person_id as count').first()
      summary.totalPeople = parseInt(peopleResult.count) || 0

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
  indexVillages (req, res) {
    Common.debug(req, 'indexVillages')

    return Knex('villages')
      .select('village_id', 'village')
      .orderBy('village', 'asc')
      .then((villages) => {
        res.send(villages)
      })
      .catch((err) => {
        Common.error(req, 'indexVillages', err)
        res.status(500).send({ error: 'an error has occurred trying to fetch villages: ' + err })
      })
  },

  async summaryLandAquisition (req, res) {
    Common.debug(req, 'summaryLandAquisition')

    const summary = {}

    try {

      const landClasses =  Knex('v_land_assets')
      .select('land_class', 'land_zone')
      .sum('area_sqm as total')
      .select(Knex.raw("SUM(CASE WHEN acquisition_class = 'Permanent' THEN area_sqm ELSE 0 END) as permanent_total"))
      .select(Knex.raw("SUM(CASE WHEN acquisition_class = 'Temporary' THEN area_sqm ELSE 0 END) as temporary_total"))
      .whereNot('acquisition_class', 'None')
      .groupBy('land_class','land_zone')

      summary.landClasses = await landClasses

      return res.send(summary)

    } catch (err) {
      Common.error(req, 'summaryLandAquisition', err)
      return res.status(500).send({ error: 'an error has occurred trying to fetch land acquisition summary: ' + err })
    }

  }
}