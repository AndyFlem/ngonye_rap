const Knex = require('../services/db')
const Common = require('./CommonDebug')('Grievances')

module.exports = {
  async index (req, res) {
    Common.debug(req, 'index', '')
    
    const person_id = parseInt(req.params.person_id, 10)
    if (!person_id) return res.status(400).send({ error: 'person_id is required' })
    try {
      const grievances = await Knex('v_grievances')
        .where({ person_id })
        .orderByRaw('created_at DESC, grievance_id DESC')
      return res.send(grievances)
    } catch (err) {
      Common.error(req, 'index', err)
      return res.status(500).send({ error: 'failed to fetch grievances: ' + err })
    }
  },

  async create (req, res) {
    Common.debug(req, 'create', '')
    // const pah = (req.params.pah || '').trim().slice(0, 9)
    // const nhs = (req.params.nhs || '').trim().slice(0, 10)
    const person_id = parseInt(req.params.person_id, 10)
    if (!person_id) return res.status(400).send({ error: 'person_id is required' })

    const grievance_link = req.body.grievance_link ? String(req.body.grievance_link).trim().slice(0, 500) || null : null
    const grievance_ref = req.body.grievance_ref ? String(req.body.grievance_ref).trim().slice(0, 50) || null : null
    const date_received = req.body.date_received ? String(req.body.date_received).trim() || null : null

    if (!grievance_link && !grievance_ref) return res.status(400).send({ error: 'grievance_link or grievance_ref is required' })

    //const entity = pah ? { pah } : { nhs }

    try {
      const [inserted] = await Knex('grievances')
        .insert({ person_id, grievance_link, grievance_ref, date_received, is_current: true, user_id: req.userId })
        .returning('grievance_id')

      const grievance = await Knex('v_grievances').where({ grievance_id: inserted.grievance_id }).first()
      return res.status(201).send(grievance)
    } catch (err) {
      Common.error(req, 'create', err)
      return res.status(500).send({ error: 'failed to create grievance: ' + err })
    }
  },

  async update (req, res) {
    Common.debug(req, 'update', '')
    const grievance_id = parseInt(req.params.grievance_id, 10)
    if (!grievance_id || isNaN(grievance_id)) return res.status(400).send({ error: 'grievance_id must be a number' })

    const fields = {}
    if ('is_current' in req.body) fields.is_current = !!req.body.is_current
    if ('grievance_link' in req.body) fields.grievance_link = req.body.grievance_link ? String(req.body.grievance_link).trim().slice(0, 500) || null : null
    if ('grievance_ref' in req.body) fields.grievance_ref = req.body.grievance_ref ? String(req.body.grievance_ref).trim().slice(0, 50) || null : null
    if ('date_received' in req.body) fields.date_received = req.body.date_received ? String(req.body.date_received).trim() || null : null

    if (Object.keys(fields).length === 0) return res.status(400).send({ error: 'no valid fields provided' })

    try {
      const count = await Knex('grievances').where({ grievance_id }).update(fields)
      if (!count) return res.status(404).send({ error: 'grievance not found' })
      return res.send({ success: true })
    } catch (err) {
      Common.error(req, 'update', err)
      return res.status(500).send({ error: 'failed to update grievance: ' + err })
    }
  },

  async destroy (req, res) {
    Common.debug(req, 'destroy', '')
    const grievance_id = parseInt(req.params.grievance_id, 10)
    if (!grievance_id || isNaN(grievance_id)) return res.status(400).send({ error: 'grievance_id must be a number' })

    try {
      const grievance = await Knex('grievances').where({ grievance_id }).first()
      if (!grievance) return res.status(404).send({ error: 'grievance not found' })

      await Knex('grievances').where({ grievance_id }).delete()

      return res.send({ success: true })
    } catch (err) {
      Common.error(req, 'destroy', err)
      return res.status(500).send({ error: 'failed to delete grievance: ' + err })
    }
  },

  async indexAll (req, res) {
    Common.debug(req, 'indexAll', '')
    try {
      const result = await Knex('v_grievances as g')
        .select()
        .orderByRaw('g.created_at DESC, g.grievance_id DESC')
      return res.send(result)
    } catch (err) {
      Common.error(req, 'indexAll', err)
      return res.status(500).send({ error: 'failed to fetch all grievances: ' + err })
    }
  }
}
