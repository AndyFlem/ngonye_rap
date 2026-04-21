const Knex = require('../services/db')
const Common = require('./CommonDebug')('RAP')

module.exports = {
  // Get households/PAHs summary for dashboard
  async householdsSummary (req, res) {
    Common.debug(req, 'householdsSummary')

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

      // Add a sum of allowances
      const allowancesResult = await Knex('v_households').sum('allowance_total as total').first()
      summary.totalAllowances = parseFloat(allowancesResult.total) || 0

      // Add a sum of structures
      const structuresResult = await Knex('v_households').sum('structures_count as total').first()
      summary.totalStructures = parseFloat(structuresResult.total) || 0

      // Add a sum of primary structures
      const primaryStructuresResult = await Knex('v_households').sum('primary_structures_count as total').first()
      summary.totalPrimaryStructures = parseFloat(primaryStructuresResult.total) || 0

      // Add a sum of secondary structures
      const secondaryStructuresResult = await Knex('v_households').sum('secondary_structures_count as total').first()
      summary.totalSecondaryStructures = parseFloat(secondaryStructuresResult.total) || 0

      res.send(summary)
    } catch (err) {
      Common.error(req, 'householdsSummary', err)
      res.status(500).send({ error: 'an error has occurred trying to fetch households summary: ' + err })
    }
  }
}