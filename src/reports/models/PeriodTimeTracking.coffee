DSObject = require('../../dscommon/DSObject')

Person = require '../../app/models/Person'
Project = require '../../app/models/Project'
Task = require '../../app/models/Task'

module.exports = class PeriodTimeTracking extends DSObject
  @begin 'PeriodTimeTracking'

  @addPool()

  @propDoc 'person', Person
  @propDoc 'project', Project
  @propNum 'taskId'
  @propStr 'taskName'
  @propMoment 'lastReport'

  @propNum 'totalMin', init: 0

  @end()
