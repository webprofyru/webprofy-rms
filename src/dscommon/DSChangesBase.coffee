assert = require('./util').assert
error = require('./util').error

DSHistory = require './DSHistory'
DSPool = require './DSPool'
DSData = require './DSData'
DSDocument = require './DSDocument'
DSDigest = require './DSDigest'

module.exports = class DSChangesBase extends DSData
  @begin 'DSChangesBase'

  @noCache()

  @propDoc 'hist', DSHistory
  @propNum 'count', init: 0

  constructor: ((referry, key) ->
    DSData.call @, referry, key, {}
    (hist = @set 'hist', new DSHistory @, "#{key}.hist").release @
    countChanges =
      add: (=> @count++; @persist(); return)
      change: (=> @persist(); return)
      remove: (=> @count--; @persist(); return)
    @__unwatch2 = unwatch = []
    for setName in @__proto__.__sets
      (set = @["_#{setName}"]).$ds_hist = hist
      (set.$ds_pool = new DSPool @, "#{key}.#{setName}.pool", set.type).release @
      set.watch(@, countChanges, true) # Note: Unwatch is not required, since isOwnerDSData is true
    return)

  saveToLocalStorage: _.noop

  persist: (-> # should be implemented by child class
    return)

  anyChange: (->
    return @get('count') > 0)

  reset: (->
    DSDigest.block (=>
      (hist = @get('hist')).startReset()
      try
        for s in @__proto__.__sets
          # Note: I should clone list first, since it will be modified by inner actions
          for item in _.map (set = @["_#{s}"]).items, ((v) -> v)
            originalItem = item.$ds_doc
            for propName of item.__change when propName != '__error' && propName != '__refreshView'
              item.set propName, originalItem.get(propName)
      finally
        hist.endReset()
      return)
    return)

  changesToMap: (->
    res = {}
    for setName in @__proto__.__sets
      props = (set = @["_#{setName}"]).type::__props
      res[setName] = (resSet = {})
      for itemKey, item of set.items
        resSet[itemKey] = (itemChanges = {})
        for propName, propChange of item.__change
          if propName != '__error' && propName != '__refreshView' && (write = props[propName].write)
            itemChanges[propName] =
              v: if propChange.v == null then null else write(propChange.v)
              s: if propChange.s == null then null else write(propChange.s)
    return res)

  loadOneDoc = ((propChange, load, type, change, propName) ->
    typeLoad = if !load.hasOwnProperty(docType = type.docType) then load[docType] = {} else load[docType]
    typeLoad[propChange[propName]] = loadList =
      if !typeLoad.hasOwnProperty(propChange[propName]) then typeLoad[propChange[propName]] = [] else typeLoad[propChange[propName]]
    loadList.push do(type, key = propChange[propName], change) -> ((doc) ->
      if assert
        if !(doc != null && doc.__proto__.constructor == type && doc.$ds_key == key)
          error.invalidArg 'doc'
      change[propName] = doc
      return)
    return)

  mapToChanges: ((map) ->
    res =
      load: load = {}
      changes: changes = {}
      
    for setName in @__proto__.__sets
      props = @["_#{setName}"].type::__props
      changes[setName] = resSet = {}
      for itemKey, item of map[setName]
        resSet[itemKey] = (itemChanges = {})
        for propName, propChange of item
          itemChanges[propName] =
            if typeof (type = (prop = props[propName]).type) == 'function' # it's propDoc
              change = {v: null, s: null}
              if propChange.v then loadOneDoc(propChange, load, type, change, 'v')
              if propChange.s then loadOneDoc(propChange, load, type, change, 's')
              change
            else if (read = prop.read)
              v: if propChange.v == null then null else read.call @, propChange.v
              s: if propChange.s == null then null else read.call @, propChange.s
            else throw new Error "Unsupported type #{type}"
    return res)

  @end()

  if assert
    @end = (->
      DSData.end.call @
      for k, v of @::__props
        if v.type == 'set' && !(v.itemType.ds_editable)
          throw new Error "Type '#{@name}': propSet '#{k}' has non-editable item type"
      return)
