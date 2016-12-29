assert = require('../../../../../dscommon/util').assert
error = require('../../../../../dscommon/util').error

DSObject = require('../../../../../dscommon/DSObject')
DSDocument = require('../../../../../dscommon/DSDocument')

module.exports = class Change extends DSObject
  @begin 'Change'
  @propDoc 'doc', DSDocument
  @propStr 'prop'
  @propStr 'value'
  @propStr 'conflict'
  @propStr 'error'
  @propBool 'isDark'
  @propNum 'index'
  @end()

