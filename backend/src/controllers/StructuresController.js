const Knex = require('../services/db')
const Common = require('./CommonDebug')('Structures')

const EXPORT_COLUMNS = {
  structure_id: 'Structure ID',
  pah: 'PAH',
  structure_class: 'Class',
  structure_type: 'Type',
  secondary_description: 'Description',
  land_zone: 'Zone',
  dimensions: 'Dimensions',
  rooms: 'Rooms',
  structure_value: 'Structure Value',
  replacement_structure_id: 'Replacement Structure ID',
  replacement_class: 'Replacement Class',
  replacement_option: 'Replacement Option',
  protected: 'Protected',
  followup_flag: 'Follow-Up Flag',
  owner_tenant: 'Owner/Tenant',
  owner_name: 'Owner Name',
  data_notes: 'Data Notes',
}

function buildSearchParams (defn) {
  const params = []
  if (defn.structure_id) { params.push(`p_structure_id=> '${defn.structure_id.replace(/'/g, "''")}'`) }
  if (defn.pah) { params.push(`p_pah=> '${defn.pah.replace(/'/g, "''")}'`) }
  if (defn.structure_class) { params.push(`p_structure_class=> '${defn.structure_class.replace(/'/g, "''")}'`) }
  if (defn.structure_type) { params.push(`p_structure_type=> '${defn.structure_type.replace(/'/g, "''")}'`) }
  if (defn.land_zone) { params.push(`p_land_zone=> '${defn.land_zone.replace(/'/g, "''")}'`) }
  if (defn.protected === true || defn.protected === false) { params.push(`p_protected=> ${defn.protected}`) }
  if (defn.followup_flag === true || defn.followup_flag === false) { params.push(`p_followup_flag=> ${defn.followup_flag}`) }
  if (defn.has_replacement === true || defn.has_replacement === false) { params.push(`p_has_replacement=> ${defn.has_replacement}`) }
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
    async summary (req, res) {
    Common.debug(req, 'summary')

    try {
      const summary = {}

      const types = await Knex('v_structures')
        .select('structure_type')
        .count('* as count')
        .sum('structure_value as value')
        //.sum({ protected_count: Knex.raw('CASE WHEN protected THEN 1 ELSE 0 END') })
        .where(function() {
          this.whereNull('protected').orWhere('protected', false)
        })
        .orderBy('structure_type', 'asc')
        .groupBy('structure_type')
      
        summary.types = types

        return res.send(summary)
    } catch (err) {
      Common.error(req, 'summary', err)
      return res.status(500).send({ error: 'an error has occurred trying to fetch the structures summary: ' + err })
    }
  },
  async indexForPAH (req, res) {
    Common.debug(req, 'indexForPAH')
    const pah = (req.params.pah || '').trim().slice(0, 120)

    if (!pah) {
      return res.status(400).send({ error: 'pah is required' })
    }

    try {
      const structures = await Knex('v_structures')
        .where({ pah })

      return res.send(structures)
    } catch (err) {
      Common.error(req, 'indexForPAH', err)
      return res.status(500).send({ error: 'an error has occurred trying to fetch the structures for the household: ' + err })
    }
  },
  async show (req, res) {
    Common.debug(req, 'show')
    const id = (req.params.id || '').trim().slice(0, 120)
    if (!id) return res.status(400).send({ error: 'id is required' })
    try {
      const structure = await Knex('v_structures')
        .where({ structure_id: id })
        .first()
      if (!structure) return res.status(404).send({ error: 'structure not found' })
      return res.send(structure)
    } catch (err) {
      Common.error(req, 'show', err)
      return res.status(500).send({ error: 'an error has occurred trying to fetch the structure: ' + err })
    }
  },
  async search (req, res) {
    Common.debug(req, 'search')
    try {
      const params = buildSearchParams(req.body)
      const qry = 'SELECT structure_id FROM public.a_structures_search(' + params.join() + ')'
      Common.debug(null, 'search', 'Query: ' + qry)
      const rws = await Knex.raw(qry)
      return res.send(rws.rows)
    } catch (err) {
      Common.error(req, 'search', err)
      return res.status(500).send({ error: 'an error has occurred trying to search structures: ' + err })
    }
  },
  async exportSearch (req, res) {
    Common.debug(req, 'exportSearch')
    try {
      const params = buildSearchParams(req.body)
      const searchCall = 'public.a_structures_search(' + params.join() + ')'
      const qry = `SELECT s.* FROM v_structures s WHERE s.structure_id IN (SELECT structure_id FROM ${searchCall}) ORDER BY s.pah, s.structure_id`
      Common.debug(null, 'exportSearch', 'Query: ' + qry)
      const rws = await Knex.raw(qry)
      const rows = rws.rows

      const fields = Object.keys(EXPORT_COLUMNS)
      const header = fields.map(f => EXPORT_COLUMNS[f]).join(',')
      const lines = rows.map(row => fields.map(f => csvEscape(row[f])).join(','))
      const csv = [header, ...lines].join('\r\n')

      res.setHeader('Content-Type', 'text/csv')
      res.setHeader('Content-Disposition', 'attachment; filename="structures_export.csv"')
      return res.send(csv)
    } catch (err) {
      Common.error(req, 'exportSearch', err)
      return res.status(500).send({ error: 'an error has occurred trying to export structures: ' + err })
    }
  },
  async patch (req, res) {
    Common.debug(req, 'patch')
    const id = (req.params.id || '').trim().slice(0, 120)
    if (!id) return res.status(400).send({ error: 'id is required' })
    const { followup_flag } = req.body
    if (typeof followup_flag !== 'boolean') return res.status(400).send({ error: 'followup_flag must be a boolean' })
    try {
      const updated = await Knex('structures')
        .where({ structure_id: id })
        .update({ followup_flag })
      if (!updated) return res.status(404).send({ error: 'structure not found' })
      return res.send({ followup_flag })
    } catch (err) {
      Common.error(req, 'patch', err)
      return res.status(500).send({ error: 'an error has occurred trying to update the structure: ' + err })
    }
  },
  async indexOptions (req, res) {
    Common.debug(req, 'indexOptions')
    const fields = ['structure_class', 'structure_type', 'land_zone']
    try {
      const result = {}
      for (const field of fields) {
        const rows = await Knex('v_structures').distinct(field).whereNotNull(field).orderBy(field)
        result[field] = rows.map(r => r[field])
      }
      return res.send(result)
    } catch (err) {
      Common.error(req, 'indexOptions', err)
      return res.status(500).send({ error: 'an error has occurred fetching structure options: ' + err })
    }
  },
}
