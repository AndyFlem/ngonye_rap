const Knex = require('../services/db')
const Common = require('./CommonDebug')('RAP')

module.exports = {
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
      .whereNot('acquisition_class', 'None')
      .groupBy('land_class','land_zone')

      summary.landClasses = await landClasses

      const acquisitionClasses = Knex('v_land_assets')
        .select('acquisition_class')
        .sum('area_sqm as total')
        .whereNot('acquisition_class', 'None')
        .groupBy('acquisition_class')

      summary.acquisitionClasses = await acquisitionClasses

      return res.send(summary)

    } catch (err) {
      Common.error(req, 'summaryLandAquisition', err)
      return res.status(500).send({ error: 'an error has occurred trying to fetch land acquisition summary: ' + err })
    }

  }
}