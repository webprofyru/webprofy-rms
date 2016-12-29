assert = require('../../dscommon/util').assert
error = require('../../dscommon/util').error

DSObject = require('../../dscommon/DSObject')

module.exports = class Project extends DSObject
  @begin 'Project'

  @addPool()

  @str = ((v) -> if v == null then '' else v.get('name'))

  @propNum 'id', init: 0
  @propStr 'name'
  @propStr 'status'

  @propObj 'people'

  @end()

