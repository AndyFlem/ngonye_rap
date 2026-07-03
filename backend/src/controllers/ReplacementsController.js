const Knex = require('../services/db')
const Common = require('./CommonDebug')('Replacements')

const EXPORT_COLUMNS = {
  replacement_structure_id: 'Replacement Structure ID',
  pah: 'PAH',
  phase: 'Phase',
  structure_id: 'Structure ID',
  flag_followup: 'Follow-Up Flag',
  replacement_type_ref: 'Type Ref',
  replacement_class: 'Class',
  replacement_option: 'Replacement Option',
  replacement_cost_2024: 'Replacement Cost 2024',
  icaoption_primary_structure: 'ICA Option: Primary Structure',
  icaoption_structure_location: 'ICA Option: Structure Location',
  protected: 'Protected',
  silumesii: 'Silumesii',
}

function buildSearchParams (defn) {
  const params = []
  if (defn.pah) { params.push(`p_pah=> '${defn.pah.replace(/'/g, "''")}'`) }
  if (defn.replacement_structure_id) { params.push(`p_replacement_structure_id=> '${defn.replacement_structure_id.replace(/'/g, "''")}'`) }
  if (defn.replacement_option) { params.push(`p_replacement_option=> '${defn.replacement_option.replace(/'/g, "''")}'`) }
  if (defn.replacement_class) { params.push(`p_replacement_class=> '${defn.replacement_class.replace(/'/g, "''")}'`) }
  if (defn.icaoption_structure_location) { params.push(`p_icaoption_structure_location=> '${defn.icaoption_structure_location.replace(/'/g, "''")}'`) }
  if (defn.protected !== undefined && defn.protected !== null) { params.push(`p_protected=> ${defn.protected}`) }
  if (defn.flag_followup !== undefined && defn.flag_followup !== null) { params.push(`p_flag_followup=> ${defn.flag_followup}`) }
  if (defn.phase) { params.push(`p_phase=> '${defn.phase.replace(/'/g, "''")}'`) }
  if (defn.silumesii !== undefined && defn.silumesii !== null) { params.push(`p_silumesii=> ${defn.silumesii}`) }
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
      const summary = {structures: {}, land:{}}

      const total = await Knex('v_replacement_structures')
        .count('* as count')
        .first()
      summary.structures.total = total.count

      // Total cost of all replacement structures
      const totalValue = await Knex('v_replacement_structures')
        .sum('replacement_cost_2024 as cost')
        .first()
      summary.structures.totalValue = totalValue.cost

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
        .sum('replacement_cost_2024 as cost')
        .sum({ protected_count: Knex.raw('CASE WHEN protected THEN 1 ELSE 0 END') })
        .orderBy('replacement_option', 'asc')
        .groupBy('replacement_option')
      summary.structures.options = options


      // Agrregate the rows of v_replacement_structures by icaoption_structure_location and count the number of rows for each
      const icaOptionStructureLocation = await Knex('v_replacement_structures')
        .select('icaoption_structure_location')
        .count('* as count')
        .sum('replacement_cost_2024 as cost')
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
  async index (req, res) {
    Common.debug(req, 'index')

    try {
      const replacements = await Knex('v_replacement_structures')
        .orderBy('pah', 'asc')

      return res.send(replacements)
    } catch (err) {
      Common.error(req, 'index', err)
      return res.status(500).send({ error: 'an error has occurred trying to fetch the replacement structures: ' + err })
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
  },
  async show (req, res) {
    Common.debug(req, 'show')
    const id = (req.params.id || '').trim().slice(0, 120)
    if (!id) return res.status(400).send({ error: 'id is required' })
    try {
      const replacement = await Knex('v_replacement_structures')
        .where({ replacement_structure_id: id })
        .first()
      if (!replacement) return res.status(404).send({ error: 'replacement structure not found' })
      return res.send(replacement)
    } catch (err) {
      Common.error(req, 'show', err)
      return res.status(500).send({ error: 'an error has occurred trying to fetch the replacement structure: ' + err })
    }
  },
  async search (req, res) {
    Common.debug(req, 'search')
    try {
      const params = buildSearchParams(req.body)
      const qry = 'SELECT replacement_structure_id FROM public.a_replacements_search(' + params.join() + ')'
      Common.debug(null, 'search', 'Query: ' + qry)
      const rws = await Knex.raw(qry)
      return res.send(rws.rows)
    } catch (err) {
      Common.error(req, 'search', err)
      return res.status(500).send({ error: 'an error has occurred trying to search replacement structures: ' + err })
    }
  },
  async exportSearch (req, res) {
    Common.debug(req, 'exportSearch')
    try {
      const params = buildSearchParams(req.body)
      const searchCall = 'public.a_replacements_search(' + params.join() + ')'
      const qry = `SELECT r.* FROM v_replacement_structures r WHERE r.replacement_structure_id IN (SELECT replacement_structure_id FROM ${searchCall}) ORDER BY r.pah, r.replacement_structure_id`
      Common.debug(null, 'exportSearch', 'Query: ' + qry)
      const rws = await Knex.raw(qry)
      const rows = rws.rows

      const fields = Object.keys(EXPORT_COLUMNS)
      const header = fields.map(f => EXPORT_COLUMNS[f]).join(',')
      const lines = rows.map(row => fields.map(f => csvEscape(row[f])).join(','))
      const csv = [header, ...lines].join('\r\n')

      res.setHeader('Content-Type', 'text/csv')
      res.setHeader('Content-Disposition', 'attachment; filename="replacements_export.csv"')
      return res.send(csv)
    } catch (err) {
      Common.error(req, 'exportSearch', err)
      return res.status(500).send({ error: 'an error has occurred trying to export replacement structures: ' + err })
    }
  },
  async patch (req, res) {
    Common.debug(req, 'patch')
    const id = (req.params.id || '').trim().slice(0, 120)
    if (!id) return res.status(400).send({ error: 'id is required' })
    const { flag_followup } = req.body
    if (typeof flag_followup !== 'boolean') return res.status(400).send({ error: 'flag_followup must be a boolean' })
    try {
      const updated = await Knex('replacement_structures')
        .where({ replacement_structure_id: id })
        .update({ flag_followup })
      if (!updated) return res.status(404).send({ error: 'replacement structure not found' })
      return res.send({ flag_followup })
    } catch (err) {
      Common.error(req, 'patch', err)
      return res.status(500).send({ error: 'an error has occurred trying to update the replacement structure: ' + err })
    }
  },
  async indexNotes (req, res) {
    Common.debug(req, 'indexNotes')
    const id = (req.params.id || '').trim().slice(0, 9)
    if (!id) return res.status(400).send({ error: 'id is required' })
    try {
      const notes = await Knex('v_replacement_structure_notes')
        .where({ replacement_structure_id: id })
        .orderBy('created_at', 'desc')
      return res.send(notes)
    } catch (err) {
      Common.error(req, 'indexNotes', err)
      return res.status(500).send({ error: 'an error has occurred fetching notes: ' + err })
    }
  },

  async createNote (req, res) {
    Common.debug(req, 'createNote')
    const id = (req.params.id || '').trim().slice(0, 9)
    const note = (req.body.note || '').trim()
    if (!id) return res.status(400).send({ error: 'id is required' })
    if (!note) return res.status(400).send({ error: 'note is required' })
    try {
      const [inserted] = await Knex('replacement_structure_notes')
        .insert({ replacement_structure_id: id, user_id: req.userId, note, created_at: Knex.fn.now() })
        .returning('note_id')
      const created = await Knex('v_replacement_structure_notes').where({ note_id: inserted.note_id }).first()
      return res.status(201).send(created)
    } catch (err) {
      Common.error(req, 'createNote', err)
      return res.status(500).send({ error: 'an error has occurred creating the note: ' + err })
    }
  },

  async destroyNote (req, res) {
    Common.debug(req, 'destroyNote')
    const note_id = parseInt(req.params.note_id, 10)
    if (isNaN(note_id)) return res.status(400).send({ error: 'note_id must be an integer' })
    try {
      const note = await Knex('replacement_structure_notes').where({ note_id }).first()
      if (!note) return res.status(404).send({ error: 'note not found' })
      await Knex('replacement_structure_notes').where({ note_id }).delete()
      return res.send({ success: true })
    } catch (err) {
      Common.error(req, 'destroyNote', err)
      return res.status(500).send({ error: 'an error has occurred deleting the note: ' + err })
    }
  },

  async indexOptions (req, res) {
    Common.debug(req, 'indexOptions')
    const fields = ['replacement_option', 'replacement_class', 'icaoption_structure_location', 'phase']
    try {
      const result = {}
      for (const field of fields) {
        const rows = await Knex('v_replacement_structures').distinct(field).whereNotNull(field).orderBy(field)
        result[field] = rows.map(r => r[field])
      }
      return res.send(result)
    } catch (err) {
      Common.error(req, 'indexOptions', err)
      return res.status(500).send({ error: 'an error has occurred fetching replacement options: ' + err })
    }
  },
}