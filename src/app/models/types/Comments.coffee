assert = require('../../../dscommon/util').assert
error = require('../../../dscommon/util').error

DSDocument = require('../../../dscommon/DSDocument')

module.exports = class Comments
  @addPropType = ((clazz) ->
    clazz.propComments = ((name, valid) ->
      if assert
        error.invalidArg 'name'if !typeof name == 'string'
        error.invalidArg 'valid' if valid && typeof valid != 'function'
      valid = if q = valid then ((value) -> return if (value == null || Array.isArray(value)) && q(value) then value else undefined)
      else ((value) -> return if value == null || value instanceof Comments then value else undefined)
      return clazz.prop {
        name
        type: 'comments'
        valid
        read: ((v) -> if v != null then new Comments(v) else null)
        str: (v) ->
          if v.list.length == 0 then ''
          else if (s = v.list[0]).length <= 20 then s
          else "#{s.substr 0, 20}..."
        equal: ((l, r) ->
          return l == r if l == null || r == null
          return false if l.list.length != r.list.length
          return false for litem, i in l.list when litem != r.list[i]
          return true)
        init: null})
    return)

  zero = moment.duration(0)

  constructor: ((persisted) ->
    if assert
      if arguments.length == 1 && typeof arguments[0] == 'object' && arguments[0].__proto__ == Comments::
        undefined
      else if arguments.length == 1 && Array.isArray persisted
        error.invalidArg 'persisted' for v in persisted when !(typeof v == 'string')
    if arguments.length == 1 && typeof (src = arguments[0]) == 'object' && src.__proto__ == Comments::
      @list = src.list.slice()
    else
      @list = persisted || []
    return)

  clone: (-> return new Comments(@))

  add: ((comment) ->
    @list.push comment
    return)

  unshift: ((comment) ->
    @list.unshift comment
    return)

  shift: (->
    return @list.shift())

  valueOf: (->
    return @list)

  clear: (->
    @list = []
    return)
