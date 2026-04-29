const config = require('../config/config')

var pg = require('pg')

pg.types.setTypeParser(20, 'text', parseInt)
pg.types.setTypeParser(1082, (value) => value)

pg.types.setTypeParser(pg.types.builtins.INT8, (value) => {
  return parseInt(value)
})

pg.types.setTypeParser(pg.types.builtins.FLOAT8, (value) => {
  return parseFloat(value)
})

pg.types.setTypeParser(pg.types.builtins.NUMERIC, (value) => {
  return parseFloat(value)
})

const knexData = require('knex')({
  client: 'pg',
  version: '10',
  debug: false,//config.development_mode,
  //searchPath: [config.db.schema || 'rap', 'public'],
  connection: {
    host: config.db.host,
    port: config.db.port,
    user: config.db.user,
    password: config.db.password,
    database: config.db.database
  }
})

module.exports = knexData