const Knex = require('../services/db')
const Common = require('./CommonDebug')('Villages')

module.exports = {
  index (req, res) {
    Common.debug(req, 'index')

    return Knex('villages')
      .select('village_id', 'village')
      .orderBy('village', 'asc')
      .then((villages) => {
        res.send(villages)
      })
      .catch((err) => {
        Common.error(req, 'index', err)
        res.status(500).send({ error: 'an error has occurred trying to fetch villages: ' + err })
      })
  }
}
