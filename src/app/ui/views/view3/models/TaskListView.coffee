DSObject = require('../../../../../dscommon/DSObject')
validate = require('../../../../../dscommon/util').validate

Task = require('../../../../models/Task')
TaskList = require('../../../../models/TaskList')

module.exports = class TaskListView extends DSObject
  @begin 'TaskListView'

  @propDoc  'taskList', TaskList
  @propList 'tasks', Task
  @propNum  'tasksCount', init: 0
  @propDuration 'totalEstimate'
  @propBool 'isExpand', init: true

  @end()

