assert = require('./util').assert
error = require('./util').error
serviceOwner = require('./util').serviceOwner

modeReleaseDataOnReload = require('./util').modeReleaseDataOnReload

DSObject = require './DSObject'

module.exports =  class DSData extends DSObject
  @begin 'DSData'

  @propObj 'params'

  @noCache = ((enable) ->
    if arguments.length == 0 || enable then @ds_noCache = true
    else delete @ds_noCache
    return)

  @addDataSource ((status, prevStatus) ->
    @["_#{setName}"].set 'status', status for setName in @__proto__.__sets
    if status == 'update' && @$ds_ref == 1 && modeReleaseDataOnReload && !@ds_noCache
      serviceOwner.remove @release serviceOwner # nothing is listening this data source
      return
    @clear() if status == 'nodata'
    return)

  _startLoad: (->
    switch (status = @get('status'))
      when 'load' then return false # already in load
      when 'update' then return false # already in update
    @set 'status', switch status
      when 'nodata' then 'load'
      when 'ready' then 'update'
    return @$ds_ref > 1) # switching to 'update' can release this object - see @addDataSource

  _endLoad: ((isSuccess) ->
    @set 'status', if isSuccess then 'ready' else 'nodata'
    return)

  constructor: ((referry, key, params) ->
    DSObject.call @, referry, key
    if assert
      if @__proto__.constructor == DSData
        throw new Error 'Cannot instantiate DSData directly'
      if typeof params != 'object'
        error.invalidArg 'params'
    @set 'params', params
    @__busySets = 0
    serviceOwner.add @addRef serviceOwner if modeReleaseDataOnReload && !@__proto__.constructor.ds_noCache
    return)

  clear: (->
    @["_#{setName}"].clear() for setName in @__proto__.__sets
    return)

  refresh: (-> # default update is a full data load
    @load()
    return)

  @end()

  @end = (->
    DSObject.end.call @
    @::__sets = (setName for setName, v of @::__props when v.type == 'set')
    return)
