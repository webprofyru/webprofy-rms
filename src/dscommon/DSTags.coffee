assert = require('./util').assert
error = require('./util').error

DSObjectBase = require('./DSObjectBase')

module.exports = class DSTags extends DSObjectBase

  @nextTags = 0

  @begin 'DSTags'

  @addPropType = ((clazz) ->
    clazz.propDSTags = ((name, valid) ->
      if assert
        error.invalidArg 'name'if !typeof name == 'string'
        error.invalidArg 'valid' if valid && typeof valid != 'function'
      valid = if q = valid then ((value) -> return if (value == null || (typeof value == 'object' && value instanceof DSTags)) && q(value) then value else undefined)
      else ((value) -> return if value == null || value instanceof DSTags then value else undefined)

      localName = "_#{name}"

      @ds_dstr.push (->
        @[localName].release @ if @[localName]
        return)

      return clazz.prop {
        name
        type: 'DSTags'
        valid
        read: ((v) -> if v != null then new DSTags(@, v) else null)
        str: ((v) -> v.value)
        init: null
        set: ((value) ->
          error.invalidValue @, name, v if typeof (value = valid(v = value)) == 'undefined'
          if (oldVal = @[localName]) != value
            @[localName] = value
            value.addRef @ if value
            if (evt = @$ds_evt)
              lst.__onChange.call lst, @, name, value, oldVal for lst in evt by -1
            oldVal.release @ if oldVal
          return)})
    return)

  @ds_dstr.push (->
    v.release @ for k, v of @map when v instanceof DSObjectBase
    return)

  constructor: (referry, enums) ->
    super referry, "#{++DSTags.nextTags}"
    if assert
      if arguments.length == 2 && typeof (src = arguments[1]) == 'object'
        undefined
      else
        error.invalidArg 'enums' unless enums == undefined || typeof enums == 'string'
    if arguments.length == 2 && typeof (src = arguments[1]) == 'object'
      if src.__proto__ == DSTags::
        @map = _.clone src.map
        @value = src.value
      else
        @map = map = _.clone enums
        @value = (_.sortBy (k for k of map)).join ', '
      value.addRef @ for key, value of @map when value instanceof DSObjectBase
    else
      @map = map = {}
      if typeof enums == 'string'
        for v in enums.split ','
          map[v.trim()] = true
      @value = (_.sortBy (k for k of map)).join ', '

  clone: (owner) -> new DSTags owner, @

  toString: -> @value

  valueOf: -> @value

  # TODO: Implement right once DSTags will be editable
  #clone: ((referry) -> return new DSTags(@))

  # if !!value == true then value will be kept in the tags collection.  Value could be even DSObject - it's will be processed with correct ref coutning
  set: ((enumValue, value) ->
    if assert
      error.invalidArg 'enumValue' unless typeof enumValue == 'string'
      error.invalidArg 'value' unless typeof value != 'undefined'
    if !!value
      alreadyIn = (map = @map).hasOwnProperty(enumValue)
      value.addRef @ if value instanceof DSObjectBase
      oldValue.release @ if (oldValue = map[enumValue]) instanceof DSObjectBase
      map[enumValue] = value
      @value = (_.sortBy (k for k of map)).join ', ' if !alreadyIn
    else if (map = @map).hasOwnProperty(enumValue)
      oldValue.release @ if (oldValue = map[enumValue]) instanceof DSObjectBase
      delete @map[enumValue]
      @value = (_.sortBy (k for k of map)).join ', '
    return @)

  get: ((enumValue) ->
    if assert
      if !(typeof enumValue == 'string')
        error.invalidArg 'enumValue'
    return if @map.hasOwnProperty(enumValue) then @map[enumValue] else false)

  any: ((map) ->
    for k of map
      return true if @map.hasOwnProperty k
    return false)

  empty: ->
    for k of @map
      return false
    true

  diff: ((src) ->
    if assert
      if !(typeof src == 'object' && src.__proto__ == DSTags::)
        error.invalidArg 'src'
    srcMap = src.map
    return ("+#{k}" for k of (map = @map) when !srcMap.hasOwnProperty(k))
            .concat ("-#{k}" for k of srcMap when !map.hasOwnProperty(k))
            .join ', ')

  @end()
