assert = require('../../dscommon/util').assert
error = require('../../dscommon/util').error

DSObject = require('../../dscommon/DSObject')
Project = require('./Project')

module.exports = class TaskList extends DSObject
  @begin 'TaskList'

  @addPool()

  @str = ((v) -> if v == null then '' else v.get('name'))

  @propNum 'id', init: 0
  @propStr 'name'
  @propDoc 'project', Project
  @propNum 'position'

  @end()

