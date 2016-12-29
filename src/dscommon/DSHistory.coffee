assert = require('./util').assert
error = require('./util').error

DSObjectBase = require './DSObjectBase'
DSObject = require './DSObject'
DSDigest = require './DSDigest'
DSDocument = require './DSDocument'

module.exports = class DSHistory extends DSObject
  @begin 'DSHistory'

  @ds_dstr.push (->
    _reset.call @
    return)

  constructor: ((referry, key) ->
    DSObject.call @, referry, key
    @hist = []
    @histTop = 0
    return)

  _reset = (->
    for h in @hist
      h.i.release @
      if typeof (val = h.o) == 'object' && val instanceof DSObjectBase
        val.release @
      if typeof (val = h.n) == 'object' && val instanceof DSObjectBase
        val.release @
    @hist = []
    @histTop = 0
    return)

  skipAdd = false
  blockId = null

  blockCount = 0

  startBlock: (->
    blockId = ++blockCount
    return)

  endBlock: (->
    blockId = null
    return)

  startReset: (->
    skipAdd = true
    _reset.call @
    return)

  endReset: (->
    skipAdd = false
    return)

  add: ((item, prop, newVal, oldVal) ->
    if assert
      if !(item != null && item.__proto__.constructor.ds_editable)
        error.invalidArg 'item'
      if !(typeof prop == 'string' && prop.length > 0)
        error.invalidArg 'prop'
      if !(0 <= ['string', 'number', 'boolean', 'object', 'undefined'].indexOf(typeof newVal))
        error.invalidArg 'newVal'
      if !(0 <= ['string', 'number', 'boolean', 'object', 'undefined'].indexOf(typeof oldVal))
        error.invalidArg 'oldVal'
    if !skipAdd
      if (hist = @hist).length > @histTop
        for h in hist[@histTop..]
          h.i.release @
          if typeof (val = h.o) == 'object' && val instanceof DSObjectBase
            val.release @
          if typeof (val = h.n) == 'object' && val instanceof DSObjectBase
            val.release @
        hist.length = @histTop
      item.addRef @
      if newVal instanceof DSObjectBase
        newVal.addRef @
      if oldVal instanceof DSObjectBase
        oldVal.addRef @
      hist.push m = {i: item, p: prop, n: newVal, o: oldVal}
      m.b = blockId if blockId
      if (@histTop = histTop = hist.length) > 200
        cnt = -1
        loop
          b = hist[++cnt].b
          while ++cnt < histTop
            if (h = hist[cnt]).b == b
              v.release @ if (v = h.n) instanceof DSObjectBase
              v.release @ if (v = h.o) instanceof DSObjectBase
            else break
          break if (histTop - cnt) <= 200
        @hist = hist = hist[cnt..]
        @histTop = hist.length
    return)

  setSameAsServer: ((item, prop) ->
    if assert
      if !(item != null && item.__proto__.constructor.ds_editable)
        error.invalidArg 'item'
      if !(typeof prop == 'string' && prop.length > 0)
        error.invalidArg 'prop'
    for h, i in @hist[...@histTop] by -1
      if h.i == item && h.p == prop
        if typeof (val = h.n) == 'object' && val instanceof DSObjectBase
          val.release @
        if typeof h.o == 'undefined' # then remove
          item.release @
          @hist.splice i, 1
          @histTop--
        else # else just remove my value
          h.n = undefined
        break
    return)

  hasUndo: (-> @histTop > 0)
  undo: (->
    return if !((histTop = @histTop) > 0)
    skipAdd = true
    try
      h = (hist = @hist)[@histTop = --histTop]
      if typeof (b = h.b) != 'number' || histTop == 0 || hist[histTop - 1].b != b # it's only one change
        if typeof (oldVal = h.o) == 'undefined' then h.i.set h.p, h.i.$ds_doc[h.p] # set server value
        else h.i.set h.p, oldVal
      else DSDigest.block (=> # it block with two or more changes
        loop
          if typeof (oldVal = h.o) == 'undefined' then h.i.set h.p, h.i.$ds_doc[h.p] # set server value
          else h.i.set h.p, oldVal
          break if histTop == 0 || (h = hist[histTop - 1]).b != b
          @histTop = --histTop
        return)
    finally
      skipAdd = false
    return)

  hasRedo: hasRedo = (-> @histTop < @hist.length)
  redo: (->
    skipAdd = true
    return if !((histTop = @histTop) < (hlen = (hist = @hist).length))
    skipAdd = true
    try
      h = hist[histTop]
      @histTop = ++histTop
      if typeof (b = h.b) != 'number' || histTop == hlen || hist[histTop].b != b # it's only one change
        if typeof (newVal = h.n) == 'undefined' then h.i.set h.p, h.i.$ds_doc[h.p] # set server value
        else h.i.set h.p, newVal
      else DSDigest.block (=> # it block with two or more changes
        loop
          if typeof (newVal = h.n) == 'undefined' then h.i.set h.p, h.i.$ds_doc[h.p] # set server value
          else h.i.set h.p, newVal
          break if histTop == hlen || (h = hist[histTop]).b != b
          @histTop = ++histTop
        return)
    finally
      skipAdd = false
    return)

  @end()
