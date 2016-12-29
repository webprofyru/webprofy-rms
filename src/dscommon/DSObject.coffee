assert = require('./util').assert
serviceOwner = require('./util').serviceOwner
totalRelease = require('./util').totalRelease
serviceOwner = require('./util').serviceOwner
error = require('./util').error

DSObjectBase = require './DSObjectBase'
DSSet = require './DSSet'
DSList = require './DSList'
DSPool = require './DSPool'

module.exports = class DSObject extends DSObjectBase

  @desc = DSObjectBase.desc = ((item) ->
    return if !item.hasOwnProperty('$ds_key')
      if item == serviceOwner then 'util.serviceOwner'
      else if typeof item == 'function' then item.docType
      else if item.$evalAsync && item.$watch then "$scope{$id: #{item.$id}}"
      else JSON.stringify(item)
    if item instanceof DSSet || item instanceof DSList || item instanceof DSPool
      if !totalRelease then item.$ds_key
      else "#{item.$ds_key}(#{item.$ds_globalId})"
    else
      if !totalRelease then "#{item.$ds_key}:#{item.__proto__.constructor.docType}"
      else "#{item.$ds_key}:#{item.__proto__.constructor.docType}(#{item.$ds_globalId})")

  constructor: ((referry, key) ->
    DSObjectBase.call @, referry, key
    if assert
      throw new Error 'Cannot instantiate DSObjectBsse directly' if @__proto__.constructor == DSObjectBase
    return)

  @addPool = ((watchOn) ->
    if !totalRelease
      @pool = new DSPool serviceOwner, "#{@docType}.pool", @, watchOn
    else
      Object.defineProperty @, 'pool',
        get: (=>
          if !@.hasOwnProperty '__pool'
            @__pool = new DSPool serviceOwner, "#{@docType}.pool", @, watchOn
            serviceOwner.clearPool (=>
              @__pool.release serviceOwner
              delete @__pool
              return)
          return @__pool)
    return)

  @propPool = ((name, itemType, watchOn) ->
    if assert
      error.invalidArg 'itemType' if !(DSObjectBase.isAssignableFrom(itemType))
    localName = "_#{name}"
    @ds_dstr.push (-> # pool got to be released last
      @[localName].release @
      delete @[localName]
      return)
    (propDecl = @prop {
      name
      type: 'pool'
      init: (-> return new DSPool @, "#{@$ds_key}.#{name}:pool<#{itemType.docType}>", itemType, watchOn)
      readonly: true}).itemType = itemType
    return propDecl)

  @propSet = ((name, itemType) ->
    if assert
      error.invalidArg 'itemType' if !(DSObjectBase.isAssignableFrom(itemType))
    localName = "_#{name}"
    @ds_dstr.push (-> @[localName].release @; return)
    (propDecl = @prop {
      name
      type: 'set'
      init: (-> return new DSSet @, "#{@$ds_key}.#{name}:set<#{itemType.docType}>", itemType, @)
      get: (-> return @[localName].items)
      set: ((v) -> throw new Error "Use #{name}Set.merge() instead"; return)
      readonly: true}).itemType = itemType
    @prop {name: "#{name}Status", type: 'calc', func: (-> return @[localName].get 'status')}
    @prop {name: "#{name}Set", type: 'calc', func: (-> return @[localName])}
    return propDecl)

  @propList = ((name, itemType) ->
    if assert
      error.invalidArg 'itemType' if !(DSObjectBase.isAssignableFrom(itemType))
    localName = "_#{name}"
    @ds_dstr.push (-> @[localName].release @; return)
    (propDecl = @prop {
      name
      type: 'list'
      init: (-> return new DSList @, "#{@$ds_key}.#{name}:list<#{itemType.docType}>", itemType)
      get: (-> return @[localName].items)
      set: ((v) -> throw new Error "Use #{name}Set.merge() instead"; return)
      readonly: true}).itemType = itemType
    @prop {name: "#{name}List", type: 'calc', func: (-> return @[localName])}
    return propDecl)
