const Knex = require('../services/db')
const Common = require('./CommonDebug')('Notes')

module.exports = {
  async index (req, res) {
    Common.debug(req, 'index', '')
    const pah = (req.params.pah || '').trim().slice(0, 9)
    const nhs = (req.params.nhs || '').trim().slice(0, 10)
    if (!pah && !nhs) return res.status(400).send({ error: 'pah or nhs is required' })
    const filter = pah ? { pah } : { nhs }
    try {
      const notes = await Knex('v_notes').where(filter).orderBy('created_at', 'desc')
      return res.send(notes)
    } catch (err) {
      Common.error(req, 'index', err)
      return res.status(500).send({ error: 'an error has occurred fetching notes: ' + err })
    }
  },

  async create (req, res) {
    Common.debug(req, 'create', '')
    const pah = (req.params.pah || '').trim().slice(0, 9)
    const nhs = (req.params.nhs || '').trim().slice(0, 10)
    const note = (req.body.note || '').trim()
    if (!pah && !nhs) return res.status(400).send({ error: 'pah or nhs is required' })
    if (!note) return res.status(400).send({ error: 'note is required' })
    const insert = { user_id: req.userId, note, created_at: Knex.fn.now() }
    if (pah) insert.pah = pah
    if (nhs) insert.nhs = nhs
    try {
      const [inserted] = await Knex('notes').insert(insert).returning('note_id')
      const created = await Knex('v_notes').where({ note_id: inserted.note_id }).first()
      return res.status(201).send(created)
    } catch (err) {
      Common.error(req, 'create', err)
      return res.status(500).send({ error: 'an error has occurred creating the note: ' + err })
    }
  },

  async destroy (req, res) {
    Common.debug(req, 'destroy', '')
    const note_id = parseInt(req.params.note_id, 10)
    if (isNaN(note_id)) return res.status(400).send({ error: 'note_id must be an integer' })
    try {
      const note = await Knex('notes').where({ note_id }).first()
      if (!note) return res.status(404).send({ error: 'note not found' })
      if (note.user_id !== req.userId) return res.status(403).send({ error: 'not authorised to delete this note' })
      await Knex('notes').where({ note_id }).delete()
      return res.send({ success: true })
    } catch (err) {
      Common.error(req, 'destroy', err)
      return res.status(500).send({ error: 'an error has occurred deleting the note: ' + err })
    }
  }
}
