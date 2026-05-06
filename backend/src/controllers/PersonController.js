const Knex = require('../services/db')
const Common = require('./CommonDebug')('Person')

module.exports = {
  async update (req, res) {
    Common.debug(req, 'update')

    const person_id = req.params.person_id
    const allowed = ['firstname', 'middlename', 'lastname', 'contact', 'nrc']
    const fields = {}
    for (const key of allowed) {
      if (key in req.body) fields[key] = req.body[key]
    }

    if (Object.keys(fields).length === 0) {
      return res.status(400).send({ error: 'no valid fields provided' })
    }

    try {
      const count = await Knex('person').where('person_id', person_id).update(fields)
      if (!count) return res.status(404).send({ error: 'person not found' })
      return res.send({ success: true })
    } catch (err) {
      Common.error(req, 'update', err)
      return res.status(500).send({ error: 'an error has occurred trying to update person: ' + err })
    }
  },

  async reverseName (req, res) {
    Common.debug(req, 'reverseName')

    const person_id = req.params.person_id

    try {
      const person = await Knex('person')
        .where('person_id', person_id)
        .first('firstname', 'lastname')

      if (!person) {
        return res.status(404).send({ error: 'person not found' })
      }

      await Knex('person')
        .where('person_id', person_id)
        .update({ firstname: person.lastname, lastname: person.firstname })

      return res.send({ success: true })

    } catch (err) {
      Common.error(req, 'reverseName', err)
      return res.status(500).send({ error: 'an error has occurred trying to reverse name: ' + err })
    }
  },

  async show (req, res) {
    Common.debug(req, 'show')

    const person_id = req.params.person_id

    try {
      const person = await Knex('v_person')
        .where('person_id', person_id)
        .first()

      if (!person) {
        return res.status(404).send({ error: 'person not found' })
      }

      return res.send(person)

    } catch (err) {
      Common.error(req, 'show', err)
      return res.status(500).send({ error: 'an error has occurred trying to fetch person: ' + err })
    }
  }
}