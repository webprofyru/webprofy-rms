module.exports = (ngModule = angular.module 'dscommon/DSView', [
  # TODO: I need to make general data service (new name DSConnector)
  require '../app/data/dsDataService'
]).name

traceView = require('./util').traceView
assert = require('./util').assert
error = require('./util').error

DSObject = require('./DSObject')
DSSet = require('./DSSet')

ngModule.factory 'DSView', ['dsDataService', '$log', ((dsDataService, $log) ->

  class Data
    get: ((propName) ->
      if assert
        error.invalidProp @, propName if !@.hasOwnProperty propName
      return @[propName])
    set: ((propName, value) ->
      if assert
        error.invalidProp @, propName if !@.hasOwnProperty propName
      return @[propName] = value)

  return class DSView extends DSObject
    @begin 'DSView'

    @begin = ((name) ->
      DSObject.begin.call @, name
      @::__src = if superSrc = @__super__.__src then _.clone superSrc else {}
      return)

    @propData = ((name, type, params) ->
      if assert
        if typeof @::_src != 'undefined'
          throw new Error "Duplicate data set name: #{name}"
        if !(typeof params == 'undefined' || (typeof params == 'object' && params != null))
          error.invalidArg 'params'
      if typeof params == 'object'
        if params.hasOwnProperty 'watch'
          watch = params.watch
          delete params.watch
        else
          watch = null
        if assert
          if !(_.isArray(watch) || watch == null)
            error.invalidArg 'params.watch'
      @::__srcLength = (index = _.size @::__src) + 1
      @::__src[name] = {name, type, watch, params, index}
      return)

    @ds_dstr.push (->
      @__unwatch1?()
      @__unwatch2?()
      for k, v of @__src
        v.unwatch?()
        v.unwatchStatus?()
        if v.hasOwnProperty('set')
          v.set.release @
      return)

    constructor: (($scope, key) ->
      DSObject.call @, $scope, key
      if assert
        if typeof $scope != 'object'
          error.invalidArg '$scope'
      @__unwatch1 = (@__scope = $scope).$on '$destroy', (=> delete @__unwatch1; @release $scope)
      @__dirty = 0
      @__src = _.cloneDeep @__proto__.__src
      @__srcList = new Array(@__proto__.__srcLength)
      @dataStatus = 'nodata'
      setDirty = (=> @__dirty++; return)
      for k, v of @__src
        watch = v.watch
        v.listener =
          add: setDirty
          remove: setDirty
          change: if !watch
              setDirty
            else ((watch) =>
                ((item, prop) =>
                  if watch.indexOf(prop) != -1 then @__dirty++
                  return))(watch)
      return)

    @prop name: 'data', type: 'DSView.data', readonly: true, init: (-> new Data())

    viewSequence = 0

    dataUpdate: ((params) ->
      if typeof params == 'undefined'
        params = {}
      if assert
        if typeof params != 'object' && params != null
          error.invalidArg 'params'
      dsDataService.requestSources @, params, @__src
      for k, v of @__src
        if v.hasOwnProperty('newSet')
          newSet = v.newSet
          if v.hasOwnProperty('set')
            v.set.release @
            v.unwatch()
            v.unwatchStatus()
          Object.defineProperty (data = @get('data')), k,
            configurable: true
            enumerable: true
            value: newSet.items
          Object.defineProperty data, "#{k}Set",
            configurable: true
            get: do (newSet) -> (-> return newSet)
          Object.defineProperty data, "#{k}Status",
            configurable: true
            get: do (newSet) -> (-> return newSet.get 'status')
          @__srcList[v.index] = v.set = newSet; delete v.newSet
          @__dirty++
          v.unwatch = newSet.watch @, v.listener

          reactOnUpdate = true
          if v.watch != null
            for k in v.watch
              reactOnUpdate = false
              break
          else reactOnUpdate = false

          v.unwatchStatus = do (reactOnUpdate) => newSet.watchStatus @, ((source, status, prevStatus) =>
            if (prevStatus = @dataStatus) != (newStatus = DSObject.integratedStatus(@__srcList))
              @dataStatus = newStatus
              if reactOnUpdate || !((newStatus == 'ready' && prevStatus == 'update') || (newStatus == 'update' && prevStatus == 'ready')) # update status is equal to ready
                @__dirty++
            return)
      if !@hasOwnProperty('__unwatch2') # on first dataUpdate
        @__unwatch2 = @__scope.$watch (=> @__dirty), ((val, oldVal) =>
          if traceView
            rest = ''
            for srcName, src of @__src
              rest += ", #{srcName}: #{src.set.get('status')}"
            console.info "#{++viewSequence}:#{DSObject.desc @}.render(): dataStatus: #{@dataStatus}#{rest}"
            debugger if viewSequence == window.viewBreak
          @render()
          return)
      return)

    @end())]
