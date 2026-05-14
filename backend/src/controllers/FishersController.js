const Knex = require('../services/db')
const Common = require('./CommonDebug')('Fishers')

const EXPORT_COLUMNS = {
  nhs: 'NHS',
  fullname: 'Full Name',
  type: 'Type',
  survey_phase: 'Survey Phase',
  social_survey: 'Social Survey',
  catch_survey: 'Catch Survey',
  catch_data_survey: 'Catch Data Survey',
  maungwe_active: 'Maungwe Active',
  maungwe_annual_earnings: 'Maungwe Annual Earnings',
  maungwe_traps: 'Maungwe Traps',
  limbelo_active: 'Limbelo Active',
  limbelo_annual_earnings: 'Limbelo Annual Earnings',
  limbelo_traps: 'Limbelo Traps',
  limbelo_annual_buckets: 'Limbelo Annual Buckets',
  limbelo_days_fished: 'Limbelo Days Fished',
  site_compensation_calc: 'Site Compensation (Calc)',
  site_compensation: 'Site Compensation',
  maungwe_annual_earn: 'Maungwe Annual Earn',
  limbelo_annual_earn: 'Limbelo Annual Earn',
  transitional_allowance: 'Transitional Allowance',
  total_compensation: 'Total Compensation',
  date_signed: 'Date Signed',
  ica_link: 'ICA Link',
  new_ica_required: 'New ICA Required',
  followup_flag: 'Follow-Up Flag',
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
  if (defn.name) { params.push(`p_name=> '${defn.name.replace(/'/g, "''")}'`) }
  if (defn.nhs)  { params.push(`p_nhs=> '${defn.nhs.replace(/'/g, "''")}'`) }
  if (defn.nrc)  { params.push(`p_nrc=> '${defn.nrc.replace(/'/g, "''")}'`) }
  if (defn.type) { params.push(`p_type=> '${defn.type.replace(/'/g, "''")}'`) }
  if (defn.survey_phase !== undefined && defn.survey_phase !== null && defn.survey_phase !== '') {
    const phase = parseInt(defn.survey_phase)
    if (!isNaN(phase)) { params.push(`p_survey_phase=> ${phase}`) }
  }
  if (defn.social_survey !== undefined && defn.social_survey !== null) {
    params.push(`p_social_survey=> ${defn.social_survey}`)
  }
  if (defn.catch_survey !== undefined && defn.catch_survey !== null) {
    params.push(`p_catch_survey=> ${defn.catch_survey}`)
  }
  if (defn.maungwe_active) { params.push(`p_maungwe_active=> '${defn.maungwe_active.replace(/'/g, "''")}'`) }
  if (defn.limbelo_active) { params.push(`p_limbelo_active=> '${defn.limbelo_active.replace(/'/g, "''")}'`) }
  if (defn.followup_flag !== undefined && defn.followup_flag !== null) { params.push(`p_followup_flag=> ${defn.followup_flag}`) }
  if (defn.ica_signed !== undefined && defn.ica_signed !== null) { params.push(`p_ica_signed=> ${defn.ica_signed}`) }
  if (defn.new_ica_required !== undefined && defn.new_ica_required !== null) { params.push(`p_new_ica_required=> ${defn.new_ica_required}`) }
  if (defn.has_multiple_icas !== undefined && defn.has_multiple_icas !== null) { params.push(`p_has_multiple_icas=> ${defn.has_multiple_icas}`) }
  if (defn.has_linked_household !== undefined && defn.has_linked_household !== null) { params.push(`p_has_linked_household=> ${defn.has_linked_household}`) }
  if (defn.has_notes !== undefined && defn.has_notes !== null) { params.push(`p_has_notes=> ${defn.has_notes}`) }
  if (defn.has_grievances !== undefined && defn.has_grievances !== null) { params.push(`p_has_grievances=> ${defn.has_grievances}`) }
  return params
}

module.exports = {
  async search (req, res) {
    Common.debug(req, 'search', '')
    try {
      const params = buildSearchParams(req.body)
      const qry = 'SELECT nhs FROM public.a_fishers_search(' + params.join() + ')'
      Common.debug(null, 'search', 'Query: ' + qry)
      const rws = await Knex.raw(qry)
      return res.send(rws.rows)
    } catch (err) {
      Common.error(req, 'search', err)
      return res.status(500).send({ error: 'an error has occurred trying to search fishers: ' + err })
    }
  },

  async show (req, res) {
    Common.debug(req, 'show', '')
    const nhs = (req.params.nhs || '').trim().slice(0, 10)
    if (!nhs) return res.status(400).send({ error: 'nhs is required' })
    try {
      const fisher = await Knex('v_fishers').where({ nhs }).first()
      if (!fisher) return res.status(404).send({ error: 'fisher not found' })

      if (fisher.person_id) {
        const person = await Knex('v_person').where({ person_id: fisher.person_id }).first()
        fisher.person = person || null
      } else {
        fisher.person = null
      }

      return res.send(fisher)
    } catch (err) {
      Common.error(req, 'show', err)
      return res.status(500).send({ error: 'an error has occurred trying to fetch the fisher: ' + err })
    }
  },

  async exportSearch (req, res) {
    Common.debug(req, 'exportSearch')
    try {
      const params = buildSearchParams(req.body)
      const searchCall = 'public.a_fishers_search(' + params.join() + ')'
      const qry = `SELECT f.* FROM v_fishers f WHERE f.nhs IN (SELECT nhs FROM ${searchCall}) ORDER BY f.nhs`
      Common.debug(null, 'exportSearch', 'Query: ' + qry)
      const rws = await Knex.raw(qry)
      const rows = rws.rows

      const fields = Object.keys(EXPORT_COLUMNS)
      const header = fields.map(f => EXPORT_COLUMNS[f]).join(',')
      const lines = rows.map(row => fields.map(f => csvEscape(row[f])).join(','))
      const csv = [header, ...lines].join('\r\n')

      res.setHeader('Content-Type', 'text/csv')
      res.setHeader('Content-Disposition', 'attachment; filename="fishers.csv"')
      return res.send(csv)
    } catch (err) {
      Common.error(req, 'exportSearch', err)
      return res.status(500).send({ error: 'an error has occurred trying to export fishers: ' + err })
    }
  },

  async patch (req, res) {
    Common.debug(req, 'patch')
    const nhs = (req.params.nhs || '').trim().slice(0, 10)
    if (!nhs) return res.status(400).send({ error: 'nhs is required' })

    const allowed = {
      new_ica_required: 'new_ica_required',
      followup_flag: 'followup_flag'
    }
    const fields = {}
    for (const [bodyKey, colName] of Object.entries(allowed)) {
      if (bodyKey in req.body) fields[colName] = req.body[bodyKey]
    }
    if (Object.keys(fields).length === 0) {
      return res.status(400).send({ error: 'no valid fields provided' })
    }

    try {
      const count = await Knex('fishers').where('nhs', nhs).update(fields)
      if (!count) return res.status(404).send({ error: 'fisher not found' })

      if ('followup_flag' in req.body) {
        const action = req.body.followup_flag ? 'set' : 'cleared'
        await Knex('notes').insert({
          user_id: req.userId,
          nhs,
          note: `Follow-up flag ${action}`,
          created_at: Knex.fn.now()
        })
      }

      if ('new_ica_required' in req.body) {
        await Knex('notes').insert({
          user_id: req.userId,
          nhs,
          note: `New ICA required set to ${req.body.new_ica_required}`,
          created_at: Knex.fn.now()
        })
      }

      return res.send({ success: true })
    } catch (err) {
      Common.error(req, 'patch', err)
      return res.status(500).send({ error: 'an error has occurred trying to update fisher: ' + err })
    }
  }
}
