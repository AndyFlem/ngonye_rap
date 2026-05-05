const Knex = require('../services/db')
const Common = require('./CommonDebug')('Replacements')

module.exports = {
  async summary (req, res) {
    Common.debug(req, 'summary')

    try {
      const summary = {structures: {}, land:{}}

      const total = await Knex('v_replacement_structures')
        .count('* as count')
        .first()
      summary.structures.total = total.count

      // Total value of all replacement structures
      const totalValue = await Knex('v_replacement_structures')
        .sum('replacement_value as value')
        .first()
      summary.structures.totalValue = totalValue.value

      // Total of all protected replacement structures
      const totalProtected = await Knex('v_replacement_structures')
        .count('* as count')
        .where('protected', true)
        .first()
      summary.structures.totalProtected = totalProtected.count

      // Agrregate the rows of v_replacement_structures by replacement_option and count the number of rows for each 
      const options = await Knex('v_replacement_structures')
        .select('replacement_option')
        .count('* as count')
        .sum('replacement_value as value')
        .sum({ protected_count: Knex.raw('CASE WHEN protected THEN 1 ELSE 0 END') })
        .orderBy('replacement_option', 'asc')
        .groupBy('replacement_option')
      summary.structures.options = options


      // Agrregate the rows of v_replacement_structures by icaoption_structure_location and count the number of rows for each
      const icaOptionStructureLocation = await Knex('v_replacement_structures')
        .select('icaoption_structure_location')
        .count('* as count')
        .sum('replacement_value as value')
        .orderBy('icaoption_structure_location', 'asc')
        .groupBy('icaoption_structure_location')
      summary.structures.icaOptionStructureLocation = icaOptionStructureLocation

      // Sum the value of replacement_land_area from v_land_parcels grouped by the value of land_class and land_zone
      const landClasses = await Knex('v_land_assets')
        .select('land_class', 'land_zone')
        .sum('replacement_land_area as total')
        .groupBy('land_class', 'land_zone')
      summary.land.classes = landClasses

      return res.send(summary)

    } catch (err) {
      Common.error(req, 'summary', err)
      return res.status(500).send({ error: 'an error has occurred trying to fetch the replacement structures summary: ' + err })
    }
  },
  async indexForPAH (req, res) {
    Common.debug(req, 'indexForPAH')
    const pah = (req.params.pah || '').trim().slice(0, 120)

    if (!pah) {
      return res.status(400).send({ error: 'pah is required' })
    }

    try {
      const replacements = await Knex('v_replacement_structures')
        .where({ pah })

      return res.send(replacements)
    } catch (err) {
      Common.error(req, 'indexForPAH', err)
      return res.status(500).send({ error: 'an error has occurred trying to fetch the replacement structures for the household: ' + err })
    }
  }
}