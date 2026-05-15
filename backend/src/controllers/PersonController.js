const Knex = require('../services/db')
const Common = require('./CommonDebug')('Person')

const EXPORT_COLUMNS = {
  person_id: 'Person ID',
  pah: 'PAH',
  nhs: 'NHS',
  fullname: 'Full Name',
  nrc: 'NRC',
  gender: 'Gender',
  year_of_birth: 'Year of Birth',
  village: 'Village',
  relationship: 'Relationship',
  marital_status: 'Marital Status',
  residential_status: 'Residential Status',
  education: 'Education',
  primary_occupation: 'Primary Occupation',
  secondary_occupation: 'Secondary Occupation',
  primary_skill: 'Primary Skill',
  secondary_skill: 'Secondary Skill',
  household_head: 'Household Head',
  cosignatory: 'Cosignatory',
  fisher: 'Fisher',
  disabled: 'Disabled',
  disabilities: 'Disabilities',
  contact: 'Contact',
  district: 'District',
  origin: 'Origin'
}

function csvEscape (val) {
  if (val === null || val === undefined) return ''
  const s = String(val)
  if (s.includes(',') || s.includes('"') || s.includes('\n') || s.includes('\r')) {
    return '"' + s.replace(/"/g, '""') + '"'
  }
  return s
}

function buildSearchParams (defn) {
  const params = []
  if (defn.name) params.push(`p_name=> '${defn.name.replace(/'/g, "''")}'`)
  if (defn.nrc)  params.push(`p_nrc=> '${defn.nrc.replace(/'/g, "''")}'`)
  if (defn.nhs)  params.push(`p_nhs=> '${defn.nhs.replace(/'/g, "''")}'`)
  if (defn.pah)  params.push(`p_pah=> '${defn.pah.replace(/'/g, "''")}'`)
  if (defn.gender) params.push(`p_gender=> '${defn.gender.replace(/'/g, "''")}'`)
  if (defn.is_fisher      !== undefined && defn.is_fisher      !== null) params.push(`p_is_fisher=> ${defn.is_fisher}`)
  if (defn.is_head        !== undefined && defn.is_head        !== null) params.push(`p_is_head=> ${defn.is_head}`)
  if (defn.is_cosignatory !== undefined && defn.is_cosignatory !== null) params.push(`p_is_cosignatory=> ${defn.is_cosignatory}`)
  if (defn.is_disabled    !== undefined && defn.is_disabled    !== null) params.push(`p_is_disabled=> ${defn.is_disabled}`)
  if (defn.has_photo      !== undefined && defn.has_photo      !== null) params.push(`p_has_photo=> ${defn.has_photo}`)
  return params
}

module.exports = {
  async search (req, res) {
    Common.debug(req, 'search')
    try {
      const params = buildSearchParams(req.body)
      const qry = 'SELECT person_id FROM public.a_person_search(' + params.join() + ')'
      Common.debug(null, 'search', 'Query: ' + qry)
      const rws = await Knex.raw(qry)
      return res.send(rws.rows)
    } catch (err) {
      Common.error(req, 'search', err)
      return res.status(500).send({ error: 'an error has occurred trying to search people: ' + err })
    }
  },

  async exportSearch (req, res) {
    Common.debug(req, 'exportSearch')
    try {
      const params = buildSearchParams(req.body)
      const searchCall = 'public.a_person_search(' + params.join() + ')'
      const qry = `SELECT p.* FROM v_person p WHERE p.person_id IN (SELECT person_id FROM ${searchCall}) ORDER BY p.lastname, p.firstname`
      Common.debug(null, 'exportSearch', 'Query: ' + qry)
      const rws = await Knex.raw(qry)
      const fields = Object.keys(EXPORT_COLUMNS)
      const header = fields.map(f => EXPORT_COLUMNS[f]).join(',')
      const lines = rws.rows.map(row => fields.map(f => csvEscape(row[f])).join(','))
      const csv = [header, ...lines].join('\r\n')
      res.setHeader('Content-Type', 'text/csv')
      res.setHeader('Content-Disposition', 'attachment; filename="people.csv"')
      return res.send(csv)
    } catch (err) {
      Common.error(req, 'exportSearch', err)
      return res.status(500).send({ error: 'an error has occurred trying to export people: ' + err })
    }
  },

  async update (req, res) {
    Common.debug(req, 'update')

    const person_id = req.params.person_id
    const allowed = [
      'firstname', 'middlename', 'lastname',
      'gender', 'contact', 'contact2', 'nrc',
      'year_of_birth', 'village_id', 'relationship', 'marital_status', 'district', 'origin',
      'primary_occupation', 'secondary_occupation', 'primary_skill', 'secondary_skill',
      'residential_status', 'education', 'disabilities', 'disabled'
    ]
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

  async fieldValues (req, res) {
    Common.debug(req, 'fieldValues')
    const allowed = ['relationship', 'marital_status', 'residential_status', 'primary_occupation', 'secondary_occupation', 'primary_skill', 'secondary_skill', 'education']
    const { field } = req.query
    if (!allowed.includes(field)) {
      return res.status(400).send({ error: 'invalid field' })
    }
    try {
      const rows = await Knex('person')
        .distinct(field)
        .whereNotNull(field)
        .where(field, '!=', '')
        .orderBy(field, 'asc')
      return res.send(rows.map(r => r[field]))
    } catch (err) {
      Common.error(req, 'fieldValues', err)
      return res.status(500).send({ error: 'an error has occurred: ' + err })
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
