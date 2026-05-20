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
  if (defn.is_deceased    !== undefined && defn.is_deceased    !== null) params.push(`p_is_deceased=> ${defn.is_deceased}`)
  return params
}

module.exports = {
  async create (req, res) {
    Common.debug(req, 'create')

    const allowed = [
      'firstname', 'middlename', 'lastname', 'gender', 'contact', 'contact2', 'nrc',
      'year_of_birth', 'village_id', 'relationship', 'marital_status', 'district', 'origin',
      'primary_occupation', 'secondary_occupation', 'primary_skill', 'secondary_skill',
      'residential_status', 'education', 'disabilities', 'disabled', 'deceased_date',
      'pah'
    ]
    const fields = {}
    for (const key of allowed) {
      if (key in req.body && req.body[key] !== '' && req.body[key] !== undefined) {
        fields[key] = req.body[key] ?? null
      }
    }
    if (fields.year_of_birth !== undefined && isNaN(parseInt(fields.year_of_birth))) fields.year_of_birth = null
    if (fields.deceased_date === '') fields.deceased_date = null

    fields.created_at = Knex.fn.now()
    fields.created_user_id = req.userId

    try {
      const [{ person_id }] = await Knex('person').insert(fields).returning('person_id')
      return res.status(201).send({ person_id })
    } catch (err) {
      Common.error(req, 'create', err)
      return res.status(500).send({ error: 'an error has occurred trying to create person: ' + err })
    }
  },

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
      'residential_status', 'education', 'disabilities', 'disabled', 'deceased_date'
    ]
    const fields = {}
    for (const key of allowed) {
      if (key in req.body) fields[key] = req.body[key]
    }

    if (fields.year_of_birth !== undefined && isNaN(parseInt(fields.year_of_birth))) {
      fields.year_of_birth = null
    }
    if (fields.deceased_date !== undefined && fields.deceased_date === '') {
      fields.deceased_date = null
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
  },

  async indexMembers (req, res) {
    Common.debug(req, 'indexMembers')
    const pah = (req.params.pah || '').trim().slice(0, 9)
    if (!pah) return res.status(400).send({ error: 'pah is required' })
    const filter = { pah }
    try {
      const members = await Knex('v_person')
        .where(filter)
        .orderBy('household_head', 'desc')
        .orderBy('cosignatory', 'desc')
        .orderBy('fullname')
      return res.send(members)
    } catch (err) {
      Common.error(req, 'indexMembers', err)
      return res.status(500).send({ error: 'an error has occurred trying to fetch members: ' + err })
    }
  },

  async mergePeople (req, res) {
    Common.debug(req, 'mergePeople')
    const { person1_id, person2_id } = req.body

    if (!person1_id || !person2_id) {
      return res.status(400).send({ error: 'person1_id and person2_id are required' })
    }
    if (Number(person1_id) === Number(person2_id)) {
      return res.status(400).send({ error: 'person1_id and person2_id must be different' })
    }

    try {
      const [p1, p2] = await Promise.all([
        Knex('v_person').where({ person_id: person1_id }).first(),
        Knex('v_person').where({ person_id: person2_id }).first()
      ])

      if (!p1) return res.status(404).send({ error: 'person 1 not found' })
      if (!p2) return res.status(404).send({ error: 'person 2 not found' })

      await Knex.transaction(async (trx) => {
        if (p2.pah) {
          if (p2.household_head) {
            await trx('households').where({ pah: p2.pah }).update({ householdhead_id: person1_id })
            await trx('person').where({ person_id: person1_id }).update({ household_head: true })
          }
          if (p2.cosignatory) {
            await trx('households').where({ pah: p2.pah }).update({ cosignatory_id: person1_id })
            await trx('person').where({ person_id: person1_id }).update({ cosignatory: true })
          }
          await trx('person').where({ person_id: person1_id }).update({ pah: p2.pah })
        }

        if (p2.nhs) {
          await trx('fishers').where({ nhs: p2.nhs }).update({ person_id: person1_id })
        }

        const copyFields = [
          'relationship', 'firstname', 'middlename', 'lastname', 'contact', 'contact2', 'nrc',
          'village_id', 'district', 'origin', 'primary_occupation', 'secondary_occupation',
          'primary_skill', 'secondary_skill', 'year_of_birth', 'gender', 'marital_status',
          'fisher_village_id'
        ]
        const updateData = {}
        for (const field of copyFields) {
          if (!p1[field] && p2[field]) updateData[field] = p2[field]
        }
        if (Object.keys(updateData).length > 0) {
          await trx('person').where({ person_id: person1_id }).update(updateData)
        }

        await trx('person').where({ person_id: person2_id }).delete()
      })

      return res.send({ success: true })
    } catch (err) {
      Common.error(req, 'mergePeople', err)
      return res.status(500).send({ error: 'error merging people: ' + err })
    }
  }
}
