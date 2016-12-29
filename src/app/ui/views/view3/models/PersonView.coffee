DSObject = require('../../../../../dscommon/DSObject')
validate = require('../../../../../dscommon/util').validate

Person = require('../../../../models/Person')
Project = require('../../../../models/Project')
ProjectView = require('./ProjectView')
TaskListView = require('./TaskListView')

Row = require('../../view1/models/Row')

module.exports = class PersonView extends DSObject
  @begin 'PersonView'

  @propDoc  'row', Row
  @propPool 'poolProjects', ProjectView
  @propList 'projects', TaskListView

  @end()

