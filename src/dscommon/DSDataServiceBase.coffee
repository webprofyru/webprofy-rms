assert = require('./util').assert
error = require('./util').error

DSObject = require './DSObject'
DSPool = require './DSPool'

module.exports = class DSDataServiceBase extends DSObject
  @begin 'DSDataService'

  findDataSet: ((owner, params) ->
    if assert
      error.invalidArg 'owner' if !((typeof owner == 'object' && owner != window) || typeof owner == 'function')
      error.invalidArg 'params' if !(typeof params == 'object' && params != null && params.hasOwnProperty('type'))
      error.invalidArg 'params.mode' if !(params.hasOwnProperty('mode') && ['original', 'edited', 'changes'].indexOf(params.mode) >= 0)
    return)

  requestSources: ((owner, params, sources) ->
    if assert
      error.invalidArg 'owner' if !((typeof owner == 'object' && owner != window) || typeof owner == 'function')
      error.invalidArg 'params' if typeof params != 'object'
      error.invalidArg 'sources' if typeof sources != 'object' || sources == null
      for k, v of sources
        if typeof v != 'object' || v == null
          error.invalidArg 'sources'
        for k2, v2 of v
          switch k2
            when 'name' then undefined
            when 'type' # model type
              error.invalidArg 'sources' if !v2 instanceof DSObject
            when 'set' # set DSSet
              error.invalidArg 'sources' if !v2 instanceof DSObject
            when 'params' # optional filter options
              error.invalidArg 'sources' if typeof v2 != 'object' || v2 == null
            when 'watch' then undefined
            when 'unwatch' then undefined
            when 'unwatchStatus' then undefined
            when 'listener' then undefined
            when 'index' then undefined
            else error.invalidArg 'sources'
    return)
  @end()
