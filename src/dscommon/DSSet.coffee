util = require('./util')
assert = require('./util').assert
traceRefs = require('./util').traceRefs
traceWatch = require('./util').traceWatch
totalReleaseVerb = require('./util').totalReleaseVerb
modeReleaseDataOnReload = require('./util').modeReleaseDataOnReload
error = require('./util').error

DSObjectBase = require('./DSObjectBase')

module.exports = class DSSet extends DSObjectBase

  @begin 'DSSet'

  @addDataSource()

  @ds_dstr.push (->
    for k, v of (items = @items)
      v.release @
      delete items[k]
    return)

  constructor: ((referry, key, type, data) ->
    DSObjectBase.call @, referry, key
    if assert
      error.notDSObjectClass type if !type instanceof DSObjectBase
      error.invalidArg 'data' if !(typeof data == 'object' || data == undefined) # Note: I cannot check 'instanceof DSData' since this will create circular dependencies
    @data = data
    @type = type
    @evt = []
    @items = {}
    return)

  __onChange: (->
    for evt in @evt by -1
      evt.change?.apply evt, arguments
    return)

  # merges old map with a new one.  maintaines proper ref-counting and event flow from items down to DSSet listeners
  # Note: merge() releases all objects within map
  merge: ((owner, newMap) ->
    if assert
      error.invalidArg 'owner' if !((typeof owner == 'object' && owner != window) || typeof owner == 'function')
      error.invalidArg 'newMap' if !(typeof newMap == 'object')
    for key, item of @items
      _remove.call @, item if !newMap.hasOwnProperty(key)
    for key, item of newMap
      if assert
        throw new Error "Invalid source map.  key: #{key}; item.$ds_key: #{item.$ds_key}" if key != item.$ds_key
      _add.call @, owner, item
    return @items)

  reset: (->
    evt = @evt
    _.forEach (items = @items), ((item) =>
      for e in evt # notify event listeners
        e.remove? item
      item.release @
      return)
    delete items[k] for k in items
    return)

  remove: ((item) ->
    if @items.hasOwnProperty(item.$ds_key)
      _remove.call @, item
    return)

  _remove = ((item) ->
    if item.hasOwnProperty '$ds_evt'
      if assert
        console.error 'Not an event listener' if !_.find item.$ds_evt, @
      _.remove item.$ds_evt, @ # unsubscribe map as the item listener
    delete @items[item.$ds_key] # remove item from local map
    for e in @evt by -1 # notify event listeners
      e.remove? item
    item.release @ # release item
    return)

  add: _add = ((owner, item) ->
    if assert
      error.invalidArg 'owner' if !((typeof owner == 'object' && owner != window) || typeof owner == 'function')
      error.invalidMapElementType @, item if !(item instanceof @type)
    if !(items = @items).hasOwnProperty(item.$ds_key)
      if !item.hasOwnProperty '$ds_evt' then item.$ds_evt = [@]
      else
        if assert
          console.error 'Already a listener' if _.find item.$ds_evt, ((lst) => lst == @)
        item.$ds_evt.push @
      items[item.$ds_key] = item # put item to local map
      if traceRefs
        refs = item.$ds_referries
        if refs.length == 0
          console.error "#{DSObjectBase.desc item}: Empty $ds_referries"
        else if (index = refs.lastIndexOf(owner)) < 0
          console.error "#{DSObjectBase.desc @}: Referry not found: #{DSObjectBase.desc owner}"
          debugger if totalReleaseVerb
        else
          if totalReleaseVerb
            console.info "#{++util.serviceOwner.msgCount}: transfer: #{DSObjectBase.desc item}, refs: #{@$ds_ref}, from: #{DSObjectBase.desc owner}, to: #{DSObjectBase.desc @}"
            debugger if util.serviceOwner.msgCount == window.totalBreak
          refs[index] = @
      for e in @evt by -1 # notify event listeners
        e.add? item
    else
      item.release owner
    return)

  clear: (->
    @merge @, {}
    @set 'status', 'nodata'
    return)

  # adds listener to the map, with appropriate controll of parameters
  watch: ((owner, listener, isOwnerDSData) ->
    if assert
      error.invalidArg 'owner' if !((typeof owner == 'object' && owner != window) || typeof owner == 'function')
      error.invalidArg 'listener' if typeof listener != 'object'
      for k, v of listener
        throw new Error "Unexpected event listener: #{k}" if k != 'change' && k != 'add' && k != 'remove'
      listener.owner = owner if traceWatch
    listener = _.clone listener if _.find @evt, ((v) -> v == listener) # clones listener if it's already in use, to support remove op
    (evt = @evt).push listener
    return if isOwnerDSData
    @addRef owner
    active = true
    return (=>
      if active
        active = false
        @release owner
        _.remove evt, ((v) -> v == listener)
      return))

  addRef: ((referry) ->
    if @$ds_ref == 1 && (data = @data)
      data.addRef (data.__backRef = @) if ++data.__busySets == 1
    DSSet.__super__.addRef.call @, referry
    return @)

  release: ((referry) ->
    DSSet.__super__.release.call @, referry
    if @$ds_ref == 1 && (data = @data)
      data.release data.__backRef if --data.__busySets == 0
    return @)

  @end()
