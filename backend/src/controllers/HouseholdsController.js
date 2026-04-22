const Knex = require('../services/db')
const Common = require('./CommonDebug')('Households')

module.exports = {
  async index (req, res) {
    Common.debug(req, 'index')

    const pah = (req.query.pah || '').trim().slice(0, 120)
    const householdHead = (req.query.household_head || '').trim().slice(0, 120)
    const nrc = (req.query.nrc || '').trim().slice(0, 120)
    const villageIdRaw = String(req.query.village_id || '').trim()
    const villageId = /^\d+$/.test(villageIdRaw) ? Number(villageIdRaw) : null

    const vulnerableOnly = req.query.vulnerable === 'true'
    const physicallyDisplacedOnly = req.query.physically_displaced === 'true'
    const nonaffectedOnly = req.query.nonaffected === 'true'

    let query = Knex('v_households')
      .select(
        'pah',
        'household_head',
        'nrc',
        'village',
        'vulnerable',
        'physically_displaced'
      )
      .orderBy('pah', 'asc')

    if (pah.length > 0) {
      query = query.whereILike('pah', `%${pah}%`)
    }

    if (householdHead.length > 0) {
      query = query.whereILike('household_head', `%${householdHead}%`)
    }

    if (nrc.length > 0) {
      query = query.whereILike('nrc', `%${nrc}%`)
    }

    if (villageId !== null) {
      query = query.where('village_id', villageId)
    }

    if (vulnerableOnly) {
      query = query.where('vulnerable', true)
    }

    if (physicallyDisplacedOnly) {
      query = query.where('physically_displaced', true)
    }

    if (nonaffectedOnly) {
      query = query.where('nonaffected', true)
    }

    try {
      const households = await query
      return res.send(households)
    } catch (err) {
      Common.error(req, 'index', err)
      return res.status(500).send({ error: 'an error has occurred trying to fetch households: ' + err })
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
  }

}
