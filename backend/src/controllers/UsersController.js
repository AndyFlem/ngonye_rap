const Knex = require('../services/db')
const Luxon = require('luxon')
const DateTime = Luxon.DateTime
const jwt = require('jsonwebtoken')
const bcrypt = require('bcryptjs')

const config = require('../config/config')
const Common = require('./CommonDebug')('User')

module.exports = {
  // =======================
  // READ
  // =======================
  index (req, res) {

    Common.debug(req, 'index')

    Knex('v_user')
      .then((users) => {
        res.send(users)
      })
      .catch(err => {
        Common.error(req, 'index', err)
        res.status(500).send({ error: 'an error has occured trying to fetch the users: ' + err })
      })
  },
  show (req, res) {
    Common.debug(req, 'show')

    module.exports.userGet(req, req.params.user_id)      
      .then((user) => {
        res.send(user)
      })
      .catch(err => {
        Common.error(req, 'show', err)
        res.status(500).send({ error: 'an error has occured trying to fetch the user: ' + err })
      })   
  },
  showCurrent (req, res) {
    Common.debug(req, 'showCurrent')

    module.exports.userGet(req, req.userId)
      .then((user) => {
        res.send(user)
      })
      .catch(err => {
        Common.error(req, 'showCurrent', err)
        res.status(500).send({ error: 'an error has occured trying to fetch the user: ' + err })
      })
  },
  userGet (req, userid) {
    Common.debug(null, 'userGet', 'User Id:  ' + userid)

    let user = null

    return Knex('v_user')
      .where({user_id: userid})
      .select()
      .then(users => {

        user = users[0]
        return Knex('v_usergroup_user')
          .where({user_id: userid})
          .select()
      })
      .then(usergroups => {
        user.groups = usergroups.map(ug => ug.usergroup_ref)
        return user
      })
  },
  usergroupsGet(req, res) {
    Common.debug(req, 'usergroupsGet')
    return Knex('v_usergroup_user')
      .where({user_id: req.params.user_id})
      .select()
      .then(usergroups => {
        res.send(usergroups)
      })
      .catch(err => {
        Common.error(req, 'usergroupsGet', err)
        res.status(500).send({ error: 'an error has occured trying to fetch the user groups: ' + err })
      })
  },
  groupsGet(req, res) {
    Common.debug(req, 'groupsGet')
    return Knex('usergroup')
      .select()
      .then(usergroups => {
        res.send(usergroups)
      })
      .catch(err => {
        Common.error(req, 'groupsGet', err)
        res.status(500).send({ error: 'an error has occured trying to fetch the groups: ' + err })
      })
  },

  // =======================
  // #region READ WRITE API
  // =======================
  // Add a user
  create (req, res) {
    Common.debug(req, 'create')

    var salt = bcrypt.genSaltSync(10)
    Common.debug(req, 'create', 'Salt: ' + salt)
    var hash = null
    Common.debug(req, 'create', 'Password: ' + req.body.password)
    if (req.body.password) { hash = bcrypt.hashSync(req.body.password, salt) }
    Common.debug(req, 'create', 'Hash: ' + hash)
    let userId = null

    Knex.transaction(function (trx) {
      Knex('user')
        .insert({
          first_name: req.body.first_name,
          last_name: req.body.last_name,
          email: req.body.email,
          password_digest: hash,
          can_login: req.body.password ? true : false,
          organisation: req.body.organisation
          })
        .returning('user_id')
        .transacting(trx)
        .then(userIds => {
          userId = userIds[0].user_id
        })
  
        .then(trx.commit)
        .catch(trx.rollback)
    })
      .then(() => {
        res.send({user_id: userId})
      })
      .catch(err => {
        Common.error(req, 'create', err)
        res.status(500).send({ error: 'an error has occured trying to create the user: ' + err })
      })
  },
  // Update user
  // app.put(prefix + '/users/:id', UsersController.update)
  update (req, res) {
    Common.debug(req, 'update')

    Knex.transaction(trx => {
      Knex('user')
      .where({user_id: req.params.user_id})
      .transacting(trx)      
      .update({
        first_name: req.body.first_name,
        last_name: req.body.last_name,
        email: req.body.email,
        can_login: req.body.can_login,
        organisation: req.body.organisation,
        is_deleted: req.body.is_deleted
      })
      // .then(() => {
      //   return Knex('usergroup_user')
      //     .where({user_id: req.params.user_id})
      //     .delete()
      //     .transacting(trx)
      // })
      // .then(() => {
      //   if (!req.body.groups.length>0) { return }
      //   return Knex('usergroup_user')
      //     .insert(req.body.groups.map(g => {return {user_id: req.params.user_id, usergroup_id: g.usergroup_id}}))
      //     .transacting(trx)
      // })
      .then(trx.commit)
      .catch(trx.rollback)
    })
      .then(() => {
        res.status(200).send({user_id: req.params.id})
      })
      .catch(err => {
        Common.error(req, 'update', err)
        res.status(500).send({ error: 'an error has occured trying to update the user: ' + err })
      })
  },

  updatePassword (req, res) {
    Common.debug(req, 'updatePassword')

    var salt = bcrypt.genSaltSync(10)
    var hash = bcrypt.hashSync(req.body.password, salt)

    Knex.transaction(trx => {
      Knex('user')
      .where({user_id: req.params.id})
      .update({password_digest: hash})
      .transacting(trx)
      .then(trx.commit)
      .catch(trx.rollback)
    })
      .then(() => {
        res.status(200).send({user_id: req.params.id})
      })
      .catch(err => {
        Common.error(req, 'updatePassword', err)
        res.status(500).send({ error: 'an error has occured trying to update the user password: ' + err })
      })
  },

  // Mark a user as deleted
  delete (req, res) {
    Common.debug(req, 'delete')

    Knex.transaction(function (trx) {
      return module.exports.userGet(req, req.params.user_id)
        .then(user => {
          if (user.pageview_count>0) {
            return Knex.raw(`UPDATE "user" SET can_login=false, is_deleted=true, last_name=concat(last_name, ' (deleted)'), email=concat(user_id,'_deleted_',email) WHERE user_id=?`, req.params.user_id)
            .transacting(trx)
            .then(trx.commit)
            .catch(trx.rollback)
          } else {
            return Knex('user')
              .where({user_id: req.params.user_id})
              .delete()
              .transacting(trx)
          }
        })
    })
      .then(() => {
        res.status(200).send({user_id: req.params.id})
      }) 
      .catch(err => {
        Common.error(req, 'delete', err)
        res.status(500).send({ error: 'an error has occured trying to delete the user: ' + err })
      })
  },

  // Signin
  signin (req, res) {
    Common.debug(req, 'signin')

    let user = null
    Knex.transaction(function (trx) {
      Knex('user')
        .where({email: req.body.email})
        .select()
        .transacting(trx)
        .then(users => {
          console.log(users)
          if (users.length === 0) {
            Common.debug(null, 'signin','User not found with email: ' + req.body.email)
            throw new Error('Not authorised!')
          }
          user = users[0]
          if (!user.can_login) {
            Common.debug(null, 'signin','User cannot login: ' + req.body.email)
            throw new Error('Not authorised!')
          }

          var passwordIsValid = bcrypt.compareSync(
            req.body.password,
            user.password_digest
          )

          if (!passwordIsValid) {
            Common.debug(null, 'signin','User password not matched: ' + req.body.email)
            throw new Error('Not authorised!')
          }
          Common.debug(null, 'signin','User password match: ' + req.body.email + ', ID: ' + user.user_id)
          user.token = jwt.sign({ id: user.user_id }, config.auth_secret, {
            expiresIn: config.auth_expiry
          })
        })
        .then(() => {
          req.userId = user.user_id
          req.user = user
          return Knex('user_login')
            .insert({user_id: user.user_id, login: DateTime.now().toISO()})
            .transacting(trx)
        })
        .then(trx.commit)
        .catch(trx.rollback)
    })
      .then(() => {
        return res.status(200).send({
          user_id: user.user_id,
          csrf: user.token
        })
      })
      .catch(err => {
        Common.debug(null, 'signin','Error: ' + err)
        res.status(401).send('Not authorised.')
      })
  },
  // #endregion  
}