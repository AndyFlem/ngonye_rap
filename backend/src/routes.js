//const debug = require('debug')('ulendo:route')
const config = require('./config/config')
const auth = require('./services/auth')

const UsersController = require('./controllers/UsersController')
const HouseholdsController = require('./controllers/HouseholdsController')
const IcasController = require('./controllers/IcasController')
const GrievancesController = require('./controllers/GrievancesController')
const RAPController = require('./controllers/RAPController')
const ReplacementsController = require('./controllers/ReplacementsController')
const LandController = require('./controllers/LandController')
const PersonController = require('./controllers/PersonController')
const FishersController = require('./controllers/FishersController')
const NotesController = require('./controllers/NotesController')

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

  app.get(prefix + '/summary', RAPController.summary)

  // PEOPLE
  app.post(prefix + '/people_search', PersonController.search)
  app.post(prefix + '/people_export', PersonController.exportSearch)
  app.post(prefix + '/people/merge', PersonController.mergePeople)
  app.get(prefix + '/people/field-values', PersonController.fieldValues)
  app.get(prefix + '/person/:person_id', PersonController.show)
  app.patch(prefix + '/person/:person_id', PersonController.update)
  app.put(prefix + '/person/:person_id/reverse-name', PersonController.reverseName)

  // HOUSEHOLDS
  app.post(prefix + '/households_search', HouseholdsController.search)
  app.post(prefix + '/households_export', HouseholdsController.exportSearch)
  app.get(prefix + '/households_ica_options', HouseholdsController.indexIcaOptions)
  app.get(prefix + '/households/:pah', HouseholdsController.show)
  app.patch(prefix + '/households/:pah', HouseholdsController.patch)
  app.get(prefix + '/households/:pah/survey', HouseholdsController.showSurvey)
  app.get(prefix + '/households/:pah/members', HouseholdsController.indexMembers)

  // NOTES (households and fishers)
  app.get(prefix + '/households/:pah/notes',  NotesController.index)
  app.post(prefix + '/households/:pah/notes', NotesController.create)
  app.get(prefix + '/fishers/:nhs/notes',     NotesController.index)
  app.post(prefix + '/fishers/:nhs/notes',    NotesController.create)
  app.delete(prefix + '/notes/:note_id',      NotesController.destroy)

  // ICAS (households and fishers)
  app.get(prefix + '/households/:pah/icas',  IcasController.index)
  app.post(prefix + '/households/:pah/icas', IcasController.create)
  app.get(prefix + '/fishers/:nhs/icas',     IcasController.index)
  app.post(prefix + '/fishers/:nhs/icas',    IcasController.create)
  app.patch(prefix + '/icas/:ica_id',        IcasController.update)

  // GRIEVANCES (households and fishers)
  app.get(prefix + '/households/:pah/grievances',  GrievancesController.index)
  app.post(prefix + '/households/:pah/grievances', GrievancesController.create)
  app.get(prefix + '/fishers/:nhs/grievances',     GrievancesController.index)
  app.post(prefix + '/fishers/:nhs/grievances',    GrievancesController.create)
  app.patch(prefix + '/grievances/:grievance_id',  GrievancesController.update)
  app.delete(prefix + '/grievances/:grievance_id', GrievancesController.destroy)

  app.get(prefix + '/households/:pah/parcels', HouseholdsController.indexParcels)
  app.get(prefix + '/households/:pah/structures', HouseholdsController.indexStructures)
  app.get(prefix + '/households/:pah/trees', HouseholdsController.indexTrees)
  app.get(prefix + '/households/:pah/crops', HouseholdsController.indexCrops)

  // REPLACEMENT STRUCTURES
  app.get(prefix + '/households/:pah/replacements', ReplacementsController.indexForPAH)
  app.get(prefix + '/replacements/summary', ReplacementsController.summary)
  app.get(prefix + '/replacements/options', ReplacementsController.indexOptions)
  app.post(prefix + '/replacements_search', ReplacementsController.search)
  app.post(prefix + '/replacements_export', ReplacementsController.exportSearch)
  app.get(prefix + '/replacements', ReplacementsController.index)
  app.get(prefix + '/replacements/:id', ReplacementsController.show)

  // LIVELIHOOD RESTORATION
  app.get(prefix + '/livelihood-restoration/households', RAPController.lrHouseholds)
  app.get(prefix + '/livelihood-restoration/fishers',    RAPController.lrFishers)

  // LAND
  app.get(prefix + '/land/summary', RAPController.summaryLandAquisition)
  app.get(prefix  + '/parcels/options', LandController.indexOptions)
  app.post(prefix + '/parcels_search',  LandController.search)
  app.post(prefix + '/parcels_export',  LandController.exportSearch)
  app.get(prefix  + '/parcels/:id/assets', LandController.indexAssets)
  app.get(prefix  + '/parcels/:id',     LandController.show)

  // FISHERS
  app.post(prefix + '/fishers_search', FishersController.search)
  app.post(prefix + '/fishers_export', FishersController.exportSearch)
  app.get(prefix + '/fishers/:nhs',    FishersController.show)
  app.patch(prefix + '/fishers/:nhs',  FishersController.patch)
  // fisher notes and icas are registered above in their respective blocks

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
