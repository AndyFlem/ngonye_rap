//const debug = require('debug')('ulendo:route')
const config = require('./config/config')
const auth = require('./services/auth')

const UsersController = require('./controllers/UsersController')
const HouseholdsController = require('./controllers/HouseholdsController')
const VillagesController = require('./controllers/VillagesController')
const RAPController = require('./controllers/RAPController')

module.exports = (app) => {
  const prefix = '/api/' + config.api_version
  // ************************************************
  // Dont require authentication
  // ************************************************
  app.post(prefix + '/signin', UsersController.signin)

  // ************************************************
  // Setup authentication
  // ************************************************
  app.use(prefix, auth.verifyToken)

  // ************************************************
  // Require authentication
  // ************************************************  

  // SUMMARY DATA
  app.get(prefix + '/households_summary', RAPController.householdsSummary)

  // HOUSEHOLDS
  app.get(prefix + '/households', HouseholdsController.index)
  app.get(prefix + '/households/:pah', HouseholdsController.show)
  app.get(prefix + '/villages', VillagesController.index)

  // USER MANAGEMENT
  app.post(prefix + '/user', UsersController.create)
  app.put(prefix + '/user/:user_id', UsersController.update)
  app.delete(prefix + '/user/:user_id', UsersController.delete)
  app.put(prefix + '/user/:id/updatepassword', UsersController.updatePassword)
  app.get(prefix + '/users', UsersController.index)
  app.get(prefix + '/user/:user_id', UsersController.show)
  app.get(prefix + '/groups', UsersController.groupsGet)
  app.get(prefix + '/current-user', UsersController.showCurrent)
  app.get(prefix + '/usergroups/:user_id', UsersController.usergroupsGet)

}
