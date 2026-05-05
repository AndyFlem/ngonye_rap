//const debug = require('debug')('ulendo:route')
const config = require('./config/config')
const auth = require('./services/auth')

const UsersController = require('./controllers/UsersController')
const HouseholdsController = require('./controllers/HouseholdsController')
const RAPController = require('./controllers/RAPController')
const ReplacementsController = require('./controllers/ReplacementsController')

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

  app.get(prefix + '/villages', RAPController.indexVillages)


  // HOUSEHOLDS
  app.get(prefix + '/households_summary', HouseholdsController.summary)
  app.post(prefix + '/households_search', HouseholdsController.search)
  app.post(prefix + '/households_export', HouseholdsController.exportSearch)
  app.get(prefix + '/households_ica_options', HouseholdsController.indexIcaOptions)
  app.get(prefix + '/households/:pah', HouseholdsController.show)

  app.get(prefix + '/households/:pah/parcels', HouseholdsController.indexParcels)
  app.get(prefix + '/households/:pah/structures', HouseholdsController.indexStructures)

  // REPLACEMENT STRUCTURES
  app.get(prefix + '/households/:pah/replacements', ReplacementsController.indexForPAH)
  app.get(prefix + '/replacements/summary', ReplacementsController.summary)

  // LAND
  app.get(prefix + '/land/summary', RAPController.summaryLandAquisition)

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
