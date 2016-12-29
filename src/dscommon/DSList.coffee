util = require('./util')
assert = require('./util').assert
traceRefs = require('./util').traceRefs
totalReleaseVerb = require('./util').totalReleaseVerb
error = require('./util').error

DSObjectBase = require './DSObjectBase'

module.exports = class DSList extends DSObjectBase

  @begin 'DSList'

  constructor: ((referry, key, type) ->
    DSObjectBase.call @, referry, key
    if assert
      if !type instanceof DSObjectBase
        error.notDSObjectClass type
    @type = type
    @items = []
    return)

  @ds_dstr.push (->
    for v in @items
      v.release @
    return)

  merge: ((owner, newList) ->
    if assert
      if !((typeof owner == 'object' && owner != window) || typeof owner == 'function')
        error.invalidArg 'owner'
      if !_.isArray(newList)
        error.invalidArg 'newList'
    items = @items
    type = @type
    for item in items
      item.release @
    items.length = 0
    for item, i in newList
      if !item instanceof type
        error.invalidListValue @, i, item
      if traceRefs
        refs = item.$ds_referries
        if refs.length == 0
          console.error "#{DSObjectBase.desc DSDitem}: Empty $ds_referries"
        else if (index = refs.lastIndexOf(owner)) < 0
          console.error "#{DSObjectBase.desc @}: Referry not found: #{DSObjectBase.desc owner}"
          debugger if totalReleaseVerb
        else
          if totalReleaseVerb
            console.info "#{++util.serviceOwner.msgCount}: transfer: #{DSObjectBase.desc item}, refs: #{@$ds_ref}, from: #{DSObjectBase.desc owner}, to: #{DSObjectBase.desc @}"
            debugger if util.serviceOwner.msgCount == window.totalBreak
          refs[index] = @
      items.push item
    return items)

  @end()
