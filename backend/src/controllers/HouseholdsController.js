const Knex = require('../services/db')
const Common = require('./CommonDebug')('Households')

module.exports = {
  index (req, res) {
    Common.debug(req, 'index')

    const queryText = (req.query.q || '').trim()
    const safeQuery = queryText.slice(0, 120)

    let query = Knex('v_households')
      .select(
        'pah',
        'household_head',
        'nrc',
        'village',
        'vulnerable',
        'physically_displaced'
      )
      .orderBy('pah', 'asc')

    if (safeQuery.length > 0) {
      const likeTerm = `%${safeQuery}%`
      query = query.where((qb) => {
        qb.whereILike('pah', likeTerm)
          .orWhereILike('household_head', likeTerm)
          .orWhereILike('nrc', likeTerm)
          .orWhereILike('village', likeTerm)
      })
    }

    query
      .then((households) => {
        res.send(households)
      })
      .catch((err) => {
        Common.error(req, 'index', err)
        res.status(500).send({ error: 'an error has occurred trying to fetch households: ' + err })
      })
  }
}
