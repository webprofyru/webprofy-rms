assert = require('../../../../../dscommon/util').assert
error = require('../../../../../dscommon/util').error

DSObject = require '../../../../../dscommon/DSObject'

Person = require '../../../../models/Person'
PersonDayStat = require '../../../../models/PersonDayStat'

TaskView = require './TaskView'

module.exports = class Row extends DSObject
  @begin 'Row'

  @propPool 'tasksPool', TaskView

  @propDoc 'person', Person
  @propDoc 'personDayStat', PersonDayStat
  @propList 'tasks', TaskView
  @propBool 'expand', init: false

  @end()

