util = require('./util')
assert = require('./util').assert
traceData = require('./util').traceData
serviceOwner = require('./util').serviceOwner
traceRefs = require('./util').traceRefs
totalRelease = require('./util').totalRelease
totalReleaseVerb = require('./util').totalReleaseVerb
error = require('./util').error

module.exports = class DSObjectBase

  @isAssignableFrom = ((clazz) ->
    error.invalidArg 'clazz' unless typeof clazz == 'function'
    return true if (up = clazz) == @
    loop
      return false if !up.hasOwnProperty '__super__'
      up = up.__super__.constructor
      return true if up == @)

  if totalRelease
    totalPool = globalId = null
    (window.totalReleaseReset = (->
      globalId = 0
      window.totalPool = totalPool = {}
      util.serviceOwner.start()
      util.serviceOwner.msgCount = 0
      return))()
    window.totalRelease = (->
      util.serviceOwner.stop()
      return totalPool)

  constructor: ((referry, key) ->
    if assert
      throw new Error 'Cannot instantiate DSObjectBаse directly' if @__proto__.constructor == DSObjectBase
      error.invalidArg 'referry' unless (typeof referry == 'object' && referry != window) || typeof referry == 'function'
      error.invalidArg 'key' if typeof key != 'string'
    @$ds_key = key
    @$ds_ref = 1
    if totalRelease
      totalPool[this.$ds_globalId = ++globalId] = this
      if totalReleaseVerb
        console.info "#{++util.serviceOwner.msgCount}: ctor: #{DSObjectBase.desc @}, refs: 1, ref: #{DSObjectBase.desc referry}"
        debugger if util.serviceOwner.msgCount == window.totalBreak
    if traceRefs
      @$ds_referries = [referry]
    if init = @__proto__.__init
      for k, v of init
        @[k] = if typeof v == 'function' then v.call @ else v
    @__proto__._init.call @
    return)

  addRef: ((referry) ->
    if assert
      error.invalidArg 'referry' unless (typeof referry == 'object' && referry != window) || typeof referry == 'function'
    if @$ds_ref == 0
      debugger if totalReleaseVerb
      throw new Error 'addRef() on already fully released object'
    if traceRefs
      @$ds_referries.push referry
    @$ds_ref++
    if totalReleaseVerb
      console.info "#{++util.serviceOwner.msgCount}:addRef: #{DSObjectBase.desc @}, refs: #{@$ds_ref}, ref: #{DSObjectBase.desc referry}"
      debugger if util.serviceOwner.msgCount == window.totalBreak
    return @)

  release: ((referry) ->
    if assert
      error.invalidArg 'referry' unless (typeof referry == 'object' && referry != window) || typeof referry == 'function'
    if totalReleaseVerb
      console.info "#{++util.serviceOwner.msgCount}: release: #{DSObjectBase.desc @}, refs: #{@$ds_ref - 1}, ref: #{DSObjectBase.desc referry}"
      debugger if util.serviceOwner.msgCount == window.totalBreak
    if @$ds_ref == 0
      debugger if totalReleaseVerb
      throw new Error 'release() on already fully released object'
    if traceRefs
      if (index = @$ds_referries.indexOf(referry)) < 0
        console.error "#{DSObjectBase.desc @}: Referry not found: #{DSObjectBase.desc referry}"
        debugger if totalReleaseVerb
      else
        @$ds_referries.splice index, 1
    if --@$ds_ref == 0
      if @.hasOwnProperty('$ds_pool')
        if (pool = @$ds_pool).watchOn
          if assert
            console.error 'Not an event listener' if !_.find @$ds_evt, ((lst) => lst == pool)
          _.remove @$ds_evt, pool
        delete @$ds_pool.items[@$ds_key]
      @__proto__._dstr.call @
      if totalRelease
        if !this.hasOwnProperty '$ds_globalId'
          throw new Error "Missing $ds_globalId, which means that something really wrong is going on"
        if !totalPool.hasOwnProperty(this.$ds_globalId)
          throw new Error "#{DSObjectBase.desc this}: Object already not in the totalPool"
        delete totalPool[this.$ds_globalId]
    return @)

  toString: (->
    return "#{@__proto__.$ds_docType}@#{@$ds_key}#{if typeof @$ds_pool == 'object' then ' <- ' + @$ds_pool else ''}")

  toJSON: -> "#{@__proto__.$ds_docType}@#{@$ds_key}"

  writeMap: (->
    res = {}
    for propName, prop of @.__proto__.__props when prop.write
        res[propName] = prop.write @["_#{propName}"]
    return res)

  readMap: ((map) ->
    props = @.__proto__.__props
    for propName, value of map
      if props.hasOwnProperty(propName) && (propDesc = props[propName]).read
        @[propName] = val = propDesc.read.call @, value
        val.release @ if val instanceof DSObjectBase
      else console.error "Unexpected property #{propName}"
    return)

  @begin = ((name) ->
    if assert
      error.invalidArg 'name' if typeof name != 'string'
    clazz = @
    @::$ds_docType = @docType = name
    @ds_ctor = if @__super__.constructor.hasOwnProperty 'ds_ctor' then _.clone @__super__.constructor.ds_ctor else []
    @ds_dstr = if @__super__.constructor.hasOwnProperty 'ds_dstr' then _.clone @__super__.constructor.ds_dstr else []
    return)

  @end = (->
    if @ds_ctor.length == 0 then @::_init = _.noop # define _init()
    else
      ctor = @ds_ctor
      @::_init = (->
        f.call @ for f in ctor
        return)
    if @ds_dstr.length == 0 then @::_dstr = _.noop # define _dstr()
    else
      dstr = @ds_dstr
      @::_dstr = (->
        f.call @ for f in dstr by -1
        return)
    return)

  @prop: ((opts) ->
    if assert
      error.invalidArg 'opts' unless typeof opts == 'object'
      throw new Error 'Missing opts.name' unless opts.hasOwnProperty('name')
      throw new Error 'Invalid value of opts.name' unless typeof opts.name == 'string' && opts.name.length > 0
      throw new Error 'Missing opts.type' if !opts.hasOwnProperty('type')
      throw new Error 'Invalid value of opts.type' unless (typeof opts.type == 'string' && opts.type.length > 0) || typeof opts.type == 'function'
      throw new Error 'Invalid value of opts.readonly' unless !opts.hasOwnProperty('readonly') || typeof opts.readonly == 'boolean'
      throw new Error 'Invalid value of opts.calc' unless typeof opts.calc == 'undefined' || typeof opts.calc == 'boolean'
      throw new Error 'Invalid value of opts.common' unless typeof opts.common == 'undefined' || typeof opts.common == 'boolean'
      throw new Error 'Invalid value of opts.func' unless !opts.hasOwnProperty('func') || typeof opts.func == 'function'
      throw new Error 'Invalid value of opts.value' unless !opts.hasOwnProperty('value') || typeof opts.value != 'function'
      throw new Error 'Missing opts.valid' if opts.hasOwnProperty('init') && !(opts.readonly || opts.calc) && !opts.hasOwnProperty('valid')
      throw new Error 'Unexpected opts.valid' if opts.hasOwnProperty('valid') && (opts.readonly || !opts.hasOwnProperty('init'))
      throw new Error "Invalid init value: #{opts.init}" if opts.hasOwnProperty('valid') && opts.valid(if typeof (init = opts.init) == 'function' then init() else init) == undefined
      throw new Error 'Invalid value of opts.valid' unless !opts.hasOwnProperty('valid') || typeof opts.valid == 'function'
      throw new Error 'Invalid value of opts.write' unless !opts.hasOwnProperty('write') || !opts.write || typeof opts.write == 'function'
      throw new Error 'Invalid value of opts.read' unless !opts.hasOwnProperty('read') || !opts.read || typeof opts.read == 'function'
      throw new Error 'Invalid value of opts.equal' unless !opts.hasOwnProperty('equal') || typeof opts.equal == 'function'
      throw new Error 'Invalid value of opts.str' unless !opts.hasOwnProperty('str') || typeof opts.str == 'function'
      throw new Error 'Invalid value of opts.get' unless !opts.hasOwnProperty('get') || typeof opts.get == 'function'
      throw new Error 'Invalid value of opts.set' unless !opts.hasOwnProperty('set') || typeof opts.set == 'function'
      throw new Error 'Ambiguous opts.readonly and opts.calc' if opts.hasOwnProperty('readonly') && !opts.readonly && opts.hasOwnProperty('calc') && opts.calc
      throw new Error 'Ambiguous opts.readonly and opts.common' if opts.hasOwnProperty('readonly') && !opts.readonly && opts.hasOwnProperty('common') && opts.common
      throw new Error 'Ambiguous opts.calc and opts.common' if opts.hasOwnProperty('calc') && opts.calc && opts.hasOwnProperty('common') && opts.common

    if !@::hasOwnProperty '__init' # create class local __init on first prop
      @::__init = if superInit = @__super__.__init then _.clone superInit else {}
      props = @::__props = if superProps = @__super__.__props then _.clone superProps else {}
      @::get = ((propName) ->
        if assert
          error.invalidProp @, propName if !props.hasOwnProperty propName
        return @[propName])
      @::set = ((propName, value) ->
        if assert
          error.invalidProp @, propName if !props.hasOwnProperty propName
        return @[propName] = value)
    else if assert
      if @::__props.hasOwnProperty opts.name
        error.duplicatedProperty @, opts.name

    propDecl = @::__props[opts.name] = { # add prop description to __props
      name: opts.name
      index: _.size @::__props
      type: opts.type
      write: opts.write || (if (opts.hasOwnProperty('write') && !opts.write) || opts.calc || opts.common then null else ((v) -> if v == null then null else v.valueOf()))
      read: opts.read || (if (opts.hasOwnProperty('read') && !opts.read) || opts.calc || opts.common then null else ((v) -> v))
      equal: equal = (opts.equal || ((l, r) -> l?.valueOf() == r?.valueOf()))
      str: opts.str || ((v) -> if v == null then '' else v.toString())
      readonly: opts.readonly || false
      calc: opts.calc || false
      common: opts.common || false}

    if opts.hasOwnProperty 'init'
      valid = propDecl.valid = opts.valid
      propDecl.init = @::__init[localName = "_#{name = opts.name}"] = opts.init
      if opts.calc
        opts.readonly == true
        @::["__setCalc#{name.substr(0, 1).toUpperCase() + name.substr(1)}"] =
          ((value) ->
            error.invalidValue @, name, v if typeof (value = valid(v = value)) == 'undefined'
            if !equal((oldVal = @[localName]), value)
              @[localName] = value
              if (evt = @$ds_evt)
                lst.__onChange.call lst, @, name, value, oldVal for lst in evt by -1
            return)
      Object.defineProperty @::, name,
        get: opts.get || (->
          return @[localName])
        set: opts.set || if opts.readonly
            ((v) -> error.propIsReadOnly @, name; return)
          else
            ((value) ->
              error.invalidValue @, name, v if typeof (value = valid(v = value)) == 'undefined'
              if !equal((oldVal = @[localName]), value)
                @[localName] = value
                if (evt = @$ds_evt)
                  lst.__onChange.call lst, @, name, value, oldVal for lst in evt by -1
              return)
    else if opts.hasOwnProperty 'value'
      propDecl.value = opts.value
      propDecl.readonly = true
      Object.defineProperty @::, opts.name, value: opts.value
    else if opts.hasOwnProperty 'func'
      propDecl.func = func = opts.func
      propDecl.readonly = true
      Object.defineProperty @::, name = opts.name,
        get: opts.get || (-> return func.call @)
        set: opts.set || ((v) -> error.propIsReadOnly @, name; return)
    else throw new Error 'Missing get value'

    return propDecl)

  @propSimple: ((type, name, opts) ->
    if assert
      error.invalidArg 'type' unless type == 'number' || type == 'boolean' || type == 'string' || type == 'object'
      error.invalidArg 'name' unless typeof name == 'string'

    valid = if q = valid then ((value) -> return if (value == null || typeof value == type) && (value = q(value)) != undefined then value else undefined)
    else ((value) -> return if value == null || typeof value == type then value else undefined)

    return @prop _.assign {
      name
      type
      init: if typeof init == 'undefined' || init == null then null else if typeof init == 'function' || type != 'object' then init else (-> return _.clone init)
      valid
      write: if opts && (opts.calc || opts.common) then null else ((v) -> v)
      read: ((v) -> v)
      equal: ((l, r) -> l == r)
      str: ((v) -> if v == null then '' else v.toString())
    }, opts)

  @propNum: ((name, opts) ->
    @propSimple 'number', name, opts
    return)

  @propBool: ((name, opts) ->
    return @propSimple 'boolean', name, opts)

  @propStr: ((name, opts) ->
    return @propSimple 'string', name, opts)

  @propObj: ((name, opts) ->
    return @propSimple 'object', name, opts)

  @propDoc: ((name, type, opts) ->
    if assert
      error.invalidArg 'name' if !typeof name == 'string'
      error.invalidArg 'valid' if valid && typeof valid != 'function'
      error.invalidArg 'type' if typeof type != 'function'
      error.notDSObjectClass type if !type instanceof DSObjectBase

    valid = if q = valid then ((value) -> return if (value == null || value instanceof type) && (value = q(value)) != undefined then value else undefined)
    else ((value) -> return if value == null || value instanceof type then value else undefined)

    localName = "_#{name}"

    @ds_dstr.push (->
      if @[localName]
        @[localName].release @
      # delete @[localName] Note: This line is commented out, cause it caused problems on $digest in View2
      return)

    return @prop _.assign {
      name
      type
      init: null
      valid
#        (if q = valid then ((value) -> return if (value == null || value instanceof type) && (value = q(value)) != undefined then value else undefined)
#        else ((value) -> return if value == null || value instanceof type then value else undefined))
      write: if opts && (opts.calc || opts.common) then null else ((v) -> if v != null then v.$ds_key else null)
      read: ((v) -> return null)
      equal: ((l, r) -> l == r)
      str: if typeof type.str == 'function' then type.str else ((v) -> if v == null then '' else v.$ds_key)
      set: ((value) ->
        error.invalidValue @, name, v if typeof (value = valid(v = value)) == 'undefined'
        if (oldVal = @[localName]) != value
          @[localName] = value
          value.addRef @ if value
          if (evt = @$ds_evt)
            lst.__onChange.call lst, @, name, value, oldVal for lst in evt by -1
          oldVal.release @ if oldVal
        return)}, opts)

  @propCalc = ((name, func, opts) ->
    if assert
      if !typeof name == 'string'
        error.invalidArg 'name'
      if !func || typeof func != 'function'
        error.invalidArg 'func'
    return @prop _.assign {name, type: 'calc', func}, opts)

  @propConst = ((name, value, opts) ->
    if assert
      if !typeof name == 'string'
        error.invalidArg 'name'
      if typeof value == 'undefined'
        error.invalidArg 'value'
    return @prop _.assign {name, type: 'const', value}, opts)

  @propEnum = ((name, values, opts) ->
    if assert
      error.invalidArg 'name' if !typeof name == 'string'
      error.invalidArg 'values' if !_.isArray(values) || values.length == 0
      error.invalidArg 'values' for s in values when !typeof s == 'string'
    valid = if q = valid then ((value) -> return if (value == null || values.indexOf(value) >= 0) && q(value) then value else undefined)
    else ((value) -> return if value == null || values.indexOf(value) >= 0 then value else undefined)
    localName = "_#{name}"
    return @prop _.assign {
      name
      type: 'enum'
      init: values[0]
      valid
      set: ((value) ->
        error.invalidValue @, name, v if typeof (value = valid(v = value)) == 'undefined'
        if (oldVal = @[localName]) != value
          @[localName] = value
          if @$ds_evt
            lst.__onChange.call lst, @, name, value, oldVal for lst in @$ds_evt by -1
        return)}, opts)

  @propMoment: ((name, valid, opts) ->
    if assert
      error.invalidArg 'name'if !typeof name == 'string'
      error.invalidArg 'valid' if valid && typeof valid != 'function'

    valid = if q = valid then ((value) -> return if (value == null || (typeof value == 'object' && moment.isMoment(value))) && q(value) then value else undefined)
    else ((value) -> return if value == null || moment.isMoment(value) then value else undefined)

    return @prop _.assign {
      name
      type: 'moment'
      valid
      read: ((v) -> if v != null then moment(v) else null)
      init: null}, opts)

  @propDuration: ((name, valid, opts) ->
    if assert
      error.invalidArg 'name'if !typeof name == 'string'
      error.invalidArg 'valid' if valid && typeof valid != 'function'

    valid = if q = valid then ((value) -> return if (value == null || (typeof value == 'object' && moment.isDuration(value))) && q(value) then value else undefined)
    else ((value) -> return if value == null || moment.isDuration(value) then value else undefined)

    return @prop _.assign {
      name
      type: 'duration'
      valid
      read: ((v) -> if v != null then moment.duration(v) else null)
      init: null}, opts)

  @onAnyPropChange: ((listener) ->
    if assert
      error.invalidArg 'listener' if typeof listener != 'function'
    @ds_ctor.push (->
      converter =
        __onChange: (=>
          listener.apply @, arguments
          return)
      if @hasOwnProperty '$ds_evt' then @$ds_evt.push converter else @$ds_evt = [converter]
      return)
    return)

  statusValues = ['nodata', 'load', 'update', 'ready']
  statusByPrior = ['ready', 'update', 'nodata', 'load']

  @integratedStatus: ((sources) ->
    if assert
      error.invalidArg 'sources' unless _.isArray(sources) && _.some(sources, ((v) -> v.__proto__.constructor.ds_dataSource))
    res = -1
    for v in sources
      if v then if res < (t = statusByPrior.indexOf(v.get('status'))) then res = t
    return if res == -1 then 'nodata' else statusByPrior[res])

  if traceData
    sourceId = 0
    sequenceId = 0

  @addDataSource = ((onStatusChange) ->
    if assert
      throw new Error 'This class already has data source mixin in it' if @ds_dataSource
      error.invalidArg 'onStatusChange' unless arguments.length == 0 || typeof onStatusChange == 'function'
    @ds_dataSource = true

    if traceData
      @ds_ctor.unshift (->
        @$ds_sourceId = ++sourceId
        console.info "#{++sequenceId}:ctor: #{DSObjectBase.desc @}(#{@$ds_sourceId})"
        debugger if sequenceId == window.sourceBreak
        return)
      @ds_dstr.push (->
        console.info "#{++sequenceId}:dstr: #{DSObjectBase.desc @}(#{@$ds_sourceId})"
        debugger if sequenceId == window.sourceBreak
        return)

    valid = ((value) -> return if value == null || statusValues.indexOf(value) >= 0 then value else undefined)

    propDecl = @prop {
        name: 'status'
        type: 'status'
        valid
        init: statusValues[0]
        set: ((value) ->
          error.invalidValue @, 'status', v if typeof (value = valid(v = value)) == 'undefined'
          if (oldVal = @_status) != value
            if traceData
              console.info "#{++sequenceId}:newStatus: #{DSObjectBase.desc @}(#{@$ds_sourceId}), new: #{value}, old: #{oldVal}"
              debugger if sequenceId == window.sourceBreak
            @_status = value
            onStatusChange?.call @, value, oldVal
            for lst in @$ds_statusWatchers by -1 # Note: Reverse order resolves collision with unwatch, during watch
              lst.lst @, value, oldVal, lst.unwatch
          return)}
    propDecl.statusValues = statusValues
    @::__init.$ds_statusWatchers = (-> [])

    @::watchStatus = ((owner, listener) ->
      if assert
        error.invalidArg 'referry' unless (typeof owner == 'object' && owner != window) || typeof owner == 'function'
        error.invalidArg 'listener' unless typeof listener == 'function'
      (watchStatus = @$ds_statusWatchers).push(w = {lst: listener})
      @addRef owner
      w.unwatch = unwatch = do (used = false) => (=> # to make possible to unwatch during listener call
        return if used
        @release owner
        _.remove watchStatus, w
        used = true
        return)
      status = @get('status')
      if status == 'update' # Note: 'update' may only go after 'ready'
        listener(@, 'ready', 'nodata', unwatch)
        listener(@, 'update', 'ready', unwatch) if _.find watchStatus, w # not unwatched yet
      else
        listener(@, status, 'nodata', unwatch)
      return unwatch)

    return)