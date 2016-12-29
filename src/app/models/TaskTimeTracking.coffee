DSObject = require('../../dscommon/DSObject')

module.exports = class TaskTimeTracking extends DSObject
  @begin 'TaskTimeTracking'

  @addPool true

  @propNum 'taskId', init: 0

  @propBool 'isReady'

  @propNum 'totalMin', init: 0
  @propNum 'priorTodayMin', init: 0

  @propObj 'timeEntries', init: {}

  # setVisible(isVisible) is implemented in the TWTimeTracking

  @end()
