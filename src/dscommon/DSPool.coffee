assert = require('./util').assert
error = require('./util').error
traceWatch = require('./util').traceWatch

DSObjectBase = require './DSObjectBase'
DSDigest = require './DSDigest'

module.exports = class DSPool extends DSObjectBase

  @begin 'DSPool'

#  @ds_dstr.push (->
#    if !_.isEmpty(@items)
#      console.error "Pool #{DSObjectBase.desc @} is not empty. Items: ", @items
#    return)

  constructor: ((referry, key, type, watchOn) ->
    DSObjectBase.call @, referry, key
    if assert
      error.notDSObjectClass type if !DSObjectBase.isAssignableFrom(type)
    items = @items = {}
    @type = type
    if watchOn
      @watchOn = true
      @evt = []
    return)

  renderItem = ((itemKey) ->
    return if !(items = @items).hasOwnProperty(itemKey)
    item = items[itemKey]
    for e in @evt by -1
      e.lst(item)
    return)

  __onChange: ((item) ->
    if @watchOn && @evt.length > 0
      DSDigest.render @$ds_key, item.$ds_key, ((itemKey) => renderItem.call @, itemKey; return)
    return)

  find: ((referry, key, map) ->
    if assert
      error.invalidArg 'key' if !(typeof key == 'string' || (typeof key == 'object' && key != null))
      error.invalidArg 'map' if !(typeof map == 'undefined' || (typeof map == 'object' && map != null))
    key = JSON.stringify (params = key) if typeof key == 'object'
    if map && map.hasOwnProperty(key)
      return map[key]
    if @items.hasOwnProperty key
      (item = @items[key]).addRef referry
    else
      item = @items[key] = new @type referry, key, params
      item.$ds_pool = @
      if @evt
        if !item.hasOwnProperty '$ds_evt' then item.$ds_evt = [@]
        else
          if assert
            console.error 'Already a listener' if _.find item.$ds_evt, ((lst) => lst == @)
          item.$ds_evt.push @
        @__onChange item
    return if map then map[key] = item else item)

  enableWatch: ((enable) ->
    if assert
      throw new Error "Pool '#{DSObjectBase.desc @}' watch functionality is not enabled" if !@evt
    @watchOn = enable
    return)

  watch: ((owner, listener) ->
    if assert
      error.invalidArg 'owner' if !((typeof owner == 'object' && owner != window) || typeof owner == 'function')
      error.invalidArg 'listener' if !(typeof listener == 'function')
      for k, v of listener
        throw new Error "Unexpected event listener: #{k}" if k != 'change' && k != 'add' && k != 'remove'
      listener.owner = owner if traceWatch
      throw new Error "Pool '#{DSObjectBase.desc @}' watch functionality is not enabled" if !@evt
    (evt = @evt).push w = {lst: listener}
    @addRef owner
    active = true
    return (=>
      if active
        active = false
        @release owner
        _.remove evt, w
      return))

  @end()
