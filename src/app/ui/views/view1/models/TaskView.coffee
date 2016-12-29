DSObject = require('../../../../../dscommon/DSObject')
validate = require('../../../../../dscommon/util').validate

Task = require('../../../../models/Task')
PersonTimeTracking = require('../../../../models/PersonTimeTracking')

module.exports = class TaskView extends DSObject
  @begin 'TaskView'

  @propDoc 'task', Task
  @propDoc 'time', PersonTimeTracking
  @propNum 'x', init: 0, valid: validate.required
  @propNum 'y', init: 0, valid: validate.required
  @propNum 'len', init: 1, valid: validate.required
  @propObj 'split'

  @end()

