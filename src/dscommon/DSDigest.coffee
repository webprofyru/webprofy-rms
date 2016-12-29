assert = require('./util').assert
error = require('./util').error

module.exports = class DSDigest

  level = 0
  block = 0
  map = {}

  renderMap = (->
    isEmpty = true; ((isEmpty = false; break) for k of map)
    return if isEmpty
    block++
    oldMap = map
    map = {}
    for dsdataKey, dsdataMap of oldMap
      for key, func of dsdataMap
        func(key)
    block--
    renderMap()
    return)

  @block = ((func) ->
    if assert
      error.invalidArg 'func' if !typeof func == 'function'
    block++
    try
      return func()
    finally
      renderMap() if --block == 0
    return)

  @render = ((dsdataKey, key, func) ->
    if assert
      error.invalidArg 'dataDataKey' if !(typeof dsdataKey == 'string' && dsdataKey.length > 0)
      error.invalidArg 'key' if !(typeof key == 'string' && key.length > 0)
      error.invalidArg 'func' if !(typeof func == 'function')
    if block == 0 then func(key)
    else
      dsdataMap = if map.hasOwnProperty(dsdataKey) then map[dsdataKey] else (map[dsdataKey] = {})
      dsdataMap[key] = func
    return)

  @forget = ((dsdataKey, key) ->
    if assert
      error.invalidArg 'dataDataKey' if !(typeof dsdataKey == 'string' && dsdataKey.length > 0)
      error.invalidArg 'key' if !(typeof key == 'string' && key.length > 0)
    if block != 0 && map.hasOwnProperty(dsdataKey)
      dsdataMap = map[dsdataKey]
      delete dsdataMap[key]
    return)
