const jwt = require('jsonwebtoken')
const Knex = require('../services/db')
const config = require('../config/config')

const debug = require('debug')('ulendo:app')

module.exports = {
  verifyToken: async (req, res, next) => {

    try {
        const tokens = req.headers['x-access-token']
        const token = Array.isArray(tokens) ? tokens[0] : tokens
        //if (true) { return res.status(401).send({ message: 'Unauthorized!' })}
        if (!token) {
          if (config.auth_disable) {
            req.userId = 1000
            req.user = {user_id: 1000, username: 'admin', email: 'admin@localhost'}
            next()          
          } else {
            debug('Token not provided. Unauthorized.')
            return res.status(401).send({message: 'Unauthorized!'})  
          }
        } else {
          const decoded = jwt.verify(token, config.auth_secret)
          if (typeof decoded === 'string') {
            debug('Invalid token')
            return res.status(401).send({ message: 'Unauthorized!' })
          }
          const payload = decoded
          req.userId = payload.id

          // debug(`Get user info from db for user Id: ${req.userId}`)
          return Knex('user')
            .where({user_id: req.userId})
            .select()
            .then(users => {
            if (users.length !== 1) {
              debug('User not found')
              return res.status(401).send({ message: 'Unauthorized!' })
            }
            if (users[0].logout) {
              debug('User logout')
              return res.status(401).send({ message: 'Unauthorized!' })
            }
            // debug('Auth success, user Id: ', req.userId)
            req.user = users[0]
            next()
          })      
        }    
    } catch (err) {
      debug('Token not verified')
      return res.status(401).send({ message: 'Unauthorized!' })
    }
  }
}
