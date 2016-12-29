DSObject = require('../../../../../dscommon/DSObject')
validate = require('../../../../../dscommon/util').validate

Project = require('../../../../models/Project')
TaskListView = require('./TaskListView')

module.exports = class ProjectView extends DSObject
  @begin 'ProjectView'

  @propDoc  'project', Project
  @propPool 'poolTaskLists', TaskListView
  @propList 'taskLists', TaskListView

  @end()

