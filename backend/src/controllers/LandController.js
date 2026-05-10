const Knex = require('../services/db')
const Common = require('./CommonDebug')('Land')

const EXPORT_COLUMNS = {
  land_parcel_id: 'Land Parcel ID',
  pah: 'PAH',
  land_class: 'Land Class',
  land_zone: 'Land Zone',
  village: 'Village',
  cultivated: 'Cultivated',
  remaining_viable: 'Remaining Viable',
  area_sqm: 'Area (sqm)',
  area_acquired: 'Area Acquired',
  cash_cost_total: 'Cash Cost Total',
  replacement_land_area: 'Replacement Land Area',
  qaqc_note: 'QAQC Note',
  qaqc_action: 'QAQC Action',
}

function buildSearchParams (defn) {
  const params = []
  if (defn.pah) { params.push(`p_pah=> '${defn.pah.replace(/'/g, "''")}'`) }
  if (defn.land_parcel_id) { params.push(`p_land_parcel_id=> '${defn.land_parcel_id.replace(/'/g, "''")}'`) }
  if (defn.land_class) { params.push(`p_land_class=> '${defn.land_class.replace(/'/g, "''")}'`) }
  if (defn.land_zone) { params.push(`p_land_zone=> '${defn.land_zone.replace(/'/g, "''")}'`) }
  if (defn.village) { params.push(`p_village=> '${defn.village.replace(/'/g, "''")}'`) }
  if (defn.cultivated !== undefined && defn.cultivated !== null) { params.push(`p_cultivated=> ${defn.cultivated}`) }
  if (defn.remaining_viable !== undefined && defn.remaining_viable !== null) { params.push(`p_remaining_viable=> ${defn.remaining_viable}`) }
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
      const qry = 'SELECT land_parcel_id FROM public.a_parcels_search(' + params.join() + ')'
      Common.debug(null, 'search', 'Query: ' + qry)
      const rws = await Knex.raw(qry)
      return res.send(rws.rows)
    } catch (err) {
      Common.error(req, 'search', err)
      return res.status(500).send({ error: 'an error has occurred trying to search land parcels: ' + err })
    }
  },
  async exportSearch (req, res) {
    Common.debug(req, 'exportSearch')
    try {
      const params = buildSearchParams(req.body)
      const searchCall = 'public.a_parcels_search(' + params.join() + ')'
      const qry = `SELECT lp.* FROM v_land_parcels lp WHERE lp.land_parcel_id IN (SELECT land_parcel_id FROM ${searchCall}) ORDER BY lp.pah, lp.land_parcel_id`
      Common.debug(null, 'exportSearch', 'Query: ' + qry)
      const rws = await Knex.raw(qry)
      const rows = rws.rows

      const fields = Object.keys(EXPORT_COLUMNS)
      const header = fields.map(f => EXPORT_COLUMNS[f]).join(',')
      const lines = rows.map(row => fields.map(f => csvEscape(row[f])).join(','))
      const csv = [header, ...lines].join('\r\n')

      res.setHeader('Content-Type', 'text/csv')
      res.setHeader('Content-Disposition', 'attachment; filename="parcels_export.csv"')
      return res.send(csv)
    } catch (err) {
      Common.error(req, 'exportSearch', err)
      return res.status(500).send({ error: 'an error has occurred trying to export land parcels: ' + err })
    }
  },
  async show (req, res) {
    Common.debug(req, 'show')
    const id = (req.params.id || '').trim().slice(0, 120)
    if (!id) return res.status(400).send({ error: 'id is required' })
    try {
      const parcel = await Knex('v_land_parcels')
        .where({ land_parcel_id: id })
        .first()
      if (!parcel) return res.status(404).send({ error: 'land parcel not found' })
      return res.send(parcel)
    } catch (err) {
      Common.error(req, 'show', err)
      return res.status(500).send({ error: 'an error has occurred trying to fetch the land parcel: ' + err })
    }
  },
  async indexAssets (req, res) {
    Common.debug(req, 'indexAssets')
    const id = (req.params.id || '').trim().slice(0, 120)
    if (!id) return res.status(400).send({ error: 'id is required' })
    try {
      const assets = await Knex('v_land_assets').where({ land_parcel_id: id })
      return res.send(assets)
    } catch (err) {
      Common.error(req, 'indexAssets', err)
      return res.status(500).send({ error: 'an error has occurred trying to fetch assets for the land parcel: ' + err })
    }
  },
  async indexOptions (req, res) {
    Common.debug(req, 'indexOptions')
    const fields = ['land_class', 'land_zone', 'village']
    try {
      const result = {}
      for (const field of fields) {
        const rows = await Knex('v_land_parcels').distinct(field).whereNotNull(field).orderBy(field)
        result[field] = rows.map(r => r[field])
      }
      return res.send(result)
    } catch (err) {
      Common.error(req, 'indexOptions', err)
      return res.status(500).send({ error: 'an error has occurred fetching parcel options: ' + err })
    }
  },
}
