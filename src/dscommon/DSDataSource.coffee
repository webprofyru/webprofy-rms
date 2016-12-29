module.exports = (ngModule = angular.module 'dscommon/DSDataSource', [
]).name

serviceOwner = require('./util').serviceOwner

modeReleaseDataOnReload = require('./util').modeReleaseDataOnReload

assert = require('./util').assert
error = require('./util').error
base64 = require '../utils/base64'

DSObject = require './DSObject'
DSDigest = require './DSDigest'

ngModule.factory 'DSDataSource', ['config', '$rootScope', '$q', '$http', ((config, $rootScope, $q, $http) ->

  return class DSDataSource extends DSObject
    @begin 'DSDataSource'

    @addDataSource()

    @setLoadAndRefresh = ((dsDataService) ->
      @set 'source', (dataSource = dsDataService.get('dataSource'))
      return dataSource.watchStatus @, ((source, status, prevStatus) =>
        switch status
          when 'ready' then DSDigest.block (=> @load())
          when 'nodata' then @set 'status', 'nodata'
        return))

    constructor: ((referry, key) ->
      DSObject.call @, referry, key
      @cancelDefers = []
      @_lastRefresh = null
      @_refreshTimer = null
      $rootScope.$watch (-> config.refreshPeriod), (val) =>
        @_setNextRefresh()
        return
      return)

    setConnection: ((url, token) ->
      if assert
        if !(url == null || (typeof url == 'string' && url.length > 0))
          error.invalidArg 'url'
        if !(typeof token == 'undefined' || token == null || (typeof token == 'string' && token.length > 0))
          error.invalidArg 'token'
      if url && (typeof token == 'undefined' || token)
        if @url != url || @token != token
          for cancel in @cancelDefers
            cancel.resolve()
          @cancelDefers.length = 0
          @set 'status', 'nodata'
          @url = url
          @authHeader = if token then "Basic #{base64.encode(token)}" else null
          @set 'status', 'ready'
      else
        @set 'status', 'nodata'
      return)

    _setNextRefresh: ->
      clearTimeout @_refreshTimer if @_refreshTimer != null
      if config.refreshPeriod != null
        timeout =
          if @_lastRefresh == null
            0
          else
            nextUpdate = @_lastRefresh.add config.refreshPeriod, 'minutes'
            currTime = moment()
            if nextUpdate >= currTime
              nextUpdate - currTime
            else
              0
        @_refreshTimer = setTimeout (=>
          @refresh()
          return), timeout
      return

    refresh: (->
      @_lastRefresh = moment()
      @_setNextRefresh()
      if @get('status') == 'ready'
        @set 'status', 'update'
        @set 'status', 'ready'
      return)

    httpGet: ((requestUrl, cancelDefer) ->
      @cancelDefers.push cancelDefer
      removeCancelDefer = ((resp) => _.remove @cancelDefers, cancelDefer; return resp)
      opts = {timeout: cancelDefer.promise}
      if @authHeader then opts.headers = {Authorization: @authHeader}
      return $http.get("#{@url}#{requestUrl}", opts).then(removeCancelDefer, removeCancelDefer))

    httpPost: ((postUrl, payload, cancelDefer) ->
      @cancelDefers.push cancelDefer
      removeCancelDefer = ((resp) => _.remove @cancelDefers, cancelDefer; return resp)
      opts = {timeout: cancelDefer.promise}
      if @authHeader then opts.headers = {Authorization: @authHeader}
      return $http.post("#{@url}#{postUrl}", payload, opts).then(removeCancelDefer, removeCancelDefer))

    httpPut: ((postUrl, payload, cancelDefer) ->
      @cancelDefers.push cancelDefer
      removeCancelDefer = ((resp) => _.remove @cancelDefers, cancelDefer; return resp)
      opts = {timeout: cancelDefer.promise}
      if @authHeader then opts.headers = {Authorization: @authHeader}
      return $http.put("#{@url}#{postUrl}", payload, opts).then(removeCancelDefer, removeCancelDefer))

    @end())]
