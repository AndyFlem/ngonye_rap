const Knex = require('../services/db')
const Common = require('./CommonDebug')('Households')

module.exports = {
  async search (req, res) {
    Common.debug(req, 'search')

    try {
      const defn = req.body
      const params = []
      let qry = 'SELECT pah FROM public.a_households_search('

      if (defn.household_head) { params.push(`p_household_head=> '${defn.household_head.replace(`'`, `''`)}'`) }
      if (defn.pah) { params.push(`p_pah=> '${defn.pah.replace(`'`, `''`)}'`) }      
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

      qry += params.join() + ')'
      if (defn.orderby) { qry += ' ORDER BY ' + defn.orderby }

      Common.debug(null, 'doSearch', 'Query: ' + qry)

      const rws = await Knex.raw(qry)
      return res.send(rws.rows)
    } catch (err) {
      Common.error(req, 'search', err)
      return res.status(500).send({ error: 'an error has occured trying to search the households: ' + err })
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

  async indexReplacements (req, res) {
    Common.debug(req, 'indexReplacements')
    const pah = (req.params.pah || '').trim().slice(0, 120)

    if (!pah) {
      return res.status(400).send({ error: 'pah is required' })
    }
    
    try {
      const replacements = await Knex('v_replacement_structures')
        .where({ pah })

      return res.send(replacements)
    } catch (err) {
      Common.error(req, 'indexReplacements', err)
      return res.status(500).send({ error: 'an error has occurred trying to fetch the replacement structures for the household: ' + err })
    }
  }
}