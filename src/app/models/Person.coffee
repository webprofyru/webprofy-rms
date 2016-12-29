assert = require('../../dscommon/util').assert
error = require('../../dscommon/util').error

DSDocument = require('../../dscommon/DSDocument')
DSTags = require('../../dscommon/DSTags')

module.exports = class Person extends DSDocument
  @begin 'Person'

  DSTags.addPropType @

  @addPool()

  @str = ((v) -> if v == null then '' else v.get('name'))

  @propNum 'id', init: 0
  @propStr 'name'
  @propStr 'firstName'
  @propStr 'avatar'
  @propStr 'email'
  @propDSTags 'roles'

  @propNum 'companyId'

  @propBool 'currentUser'

  @propBool 'missing' # in the reporting we may have deal with a case when person is deleted

  @propDuration 'contractTime'

  constructor: ((referry, key) ->
    DSDocument.call @, referry, key
    @set 'contractTime', moment.duration(8, 'hours')
    return)

  @end()

