assert = require('../../dscommon/util').assert
error = require('../../dscommon/util').error

DSDocument = require('../../dscommon/DSDocument')

module.exports = class Tag extends DSDocument
  @begin 'Tag'

  @addPool()

  @propNum 'id', init: 0
  @propStr 'name'
  @propStr 'color' # color from tags.json, if such
  @propStr 'twColor' # original color from Teamwork
  @propStr 'border'
  @propNum 'priority', init: 1000

  @end()

