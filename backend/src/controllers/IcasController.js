const Knex = require('../services/db')
const Common = require('./CommonDebug')('Icas')

module.exports = {
  async index (req, res) {
    Common.debug(req, 'index')
    const pah = (req.params.pah || '').trim().slice(0, 120)
    const nhs = (req.params.nhs || '').trim().slice(0, 10)
    if (!pah && !nhs) return res.status(400).send({ error: 'pah or nhs is required' })
    const filter = pah ? { pah } : { nhs }
    try {
      const icas = await Knex('icas')
        .where(filter)
        .orderByRaw('date_signed DESC NULLS LAST, ica_id DESC')
      return res.send(icas)
    } catch (err) {
      Common.error(req, 'index', err)
      return res.status(500).send({ error: 'failed to fetch icas: ' + err })
    }
  },

  async create (req, res) {
    Common.debug(req, 'create')
    const pah = (req.params.pah || '').trim().slice(0, 120)
    const nhs = (req.params.nhs || '').trim().slice(0, 10)
    if (!pah && !nhs) return res.status(400).send({ error: 'pah or nhs is required' })

    const ica_link = req.body.ica_link ? String(req.body.ica_link).trim().slice(0, 500) || null : null
    const date_signed = req.body.date_signed || null

    let type
    if (nhs) {
      type = 'Fisher'
    } else {
      const VALID_TYPES = ['Household', 'Non-affected']
      type = VALID_TYPES.includes(req.body.type) ? req.body.type : null
    }

    if (!ica_link && !date_signed) {
      return res.status(400).send({ error: 'ica_link or date_signed is required' })
    }

    const filter = pah ? { pah } : { nhs }

    try {
      await Knex('icas').where(filter).update({ is_current: false })

      const insert = { ica_link, date_signed, is_current: true, type }
      if (pah) insert.pah = pah
      if (nhs) insert.nhs = nhs

      const [inserted] = await Knex('icas').insert(insert).returning('ica_id')

      await Knex('notes').insert({
        user_id: req.userId,
        ...(pah ? { pah } : { nhs }),
        note: 'New, replacement ICA added',
        created_at: Knex.fn.now()
      })

      const ica = await Knex('icas').where({ ica_id: inserted.ica_id }).first()
      return res.status(201).send(ica)
    } catch (err) {
      Common.error(req, 'create', err)
      return res.status(500).send({ error: 'failed to create ica: ' + err })
    }
  },

  async update (req, res) {
    Common.debug(req, 'update')
    const ica_id = parseInt(req.params.ica_id, 10)
    if (!ica_id || isNaN(ica_id)) return res.status(400).send({ error: 'ica_id must be a number' })

    const fields = {}
    if ('ica_link' in req.body) fields.ica_link = req.body.ica_link ? String(req.body.ica_link).trim().slice(0, 500) || null : null
    if ('date_signed' in req.body) fields.date_signed = req.body.date_signed || null

    if (Object.keys(fields).length === 0) {
      return res.status(400).send({ error: 'no valid fields provided' })
    }

    try {
      const count = await Knex('icas').where({ ica_id }).update(fields)
      if (!count) return res.status(404).send({ error: 'ica not found' })
      return res.send({ success: true })
    } catch (err) {
      Common.error(req, 'update', err)
      return res.status(500).send({ error: 'failed to update ica: ' + err })
    }
  }
}
