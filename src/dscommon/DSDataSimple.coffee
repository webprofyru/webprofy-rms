module.exports = (ngModule = angular.module 'dscommon/DSDataSimple', [
]).name

assert = require('./util').assert
error = require('./util').error

DSData = require './DSData'
DSDigest = require './DSDigest'

ngModule.factory 'DSDataSimple', ['DSDataSource', '$rootScope', '$q', ((DSDataSource, $rootScope, $q) ->

  return class DSDataSimple extends DSData
    @begin 'DSDataSimple'

    @propDoc 'source', DSDataSource
    @propObj 'cancel', init: null
    @propEnum 'method', ['httpGet', 'httpPost', 'httpPut']

    @propStr 'request'

    @ds_dstr.push (->
      cancel.resolve() if cancel = @get('cancel')
      return)

    clear: (->
      DSData::clear.call @
      cancel.resolve() if cancel = @get('cancel')
      return)

    load: (->
      if assert
        throw new Error 'load(): Source is not specified' if !@get('source')
        throw new Error 'load(): Request is not specified' if !(typeof (request = @get('request')) == 'string' && request.length > 0)

      return unless @_startLoad()

      cancel = @set('cancel', $q.defer())

      onError = ((error, isCancelled) =>
        if !isCancelled
          console.error 'error: ', error
          @set 'cancel', null
        @_endLoad false
        return)

      return (
        switch (method = @get 'method')
          when 'httpGet' then @get('source').httpGet(@get('request'), cancel)
          when 'httpPost' then @get('source').httpPost(@get('request'), @params.json, cancel)
          when 'httpPut' then @get('source').httpPut(@get('request'), @params.json, cancel))
        .then(
          ((resp) => # ok
            if (resp.status == 200) # 0 means that request was canceled
              @set 'cancel', null
              @_endLoad DSDigest.block (=> @importResponse(resp.data, resp.status))
            else onError(resp, resp.status == 0)
            return), onError))

    @end())]
