DSObject = require('../../dscommon/DSObject')

Task = require('../models/Task')

module.exports = class PersonTimeTracking extends DSObject
  @begin 'PersonTimeTracking'

  @addPool true

  @propNum 'personId', init: 0
  @propMoment 'date'

  @propNum 'taskId', init: 0
  @propDoc 'task', Task

  @propNum 'timeMin', init: 0

  # setVisible(isVisible) is implemented in the TWTask

  @end()
