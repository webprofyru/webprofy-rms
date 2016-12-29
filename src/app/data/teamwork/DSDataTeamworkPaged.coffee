# This just like DSDataSimple, but supports teamwork paged load

module.exports = (ngModule = angular.module 'dscommon/DSDataTeamworkPaged', [
]).name

assert = require('../../../dscommon/util').assert
error = require('../../../dscommon/util').error

DSData = require '../../../dscommon/DSData'
DSDigest = require '../../../dscommon/DSDigest'

WORK_ENTRIES_WHOLE_PAGE = 500

ngModule.factory 'DSDataTeamworkPaged', ['DSDataSource', '$rootScope', '$q', ((DSDataSource, $rootScope, $q) ->

  return class DSDataTeamworkPaged extends DSData
    @begin 'DSDataTeamworkPaged'

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

      addPaging = (page, url) ->
        "#{url}#{if url.indexOf('?') == -1 then '?' else '&'}page=#{page}&pageSize=#{WORK_ENTRIES_WHOLE_PAGE}"

      @startLoad()

      (pageLoad = (page) =>
        (switch (method = @get 'method')
          when 'httpGet' then @get('source').httpGet addPaging(page, @get('request')), cancel
          when 'httpPost' then @get('source').httpPost addPaging(page, @get('request')), @params.json, cancel
          when 'httpPut' then @get('source').httpPut addPaging(page, @get('request')), @params.json, cancel)
        .then(
          ((resp) => # ok
            if (resp.status == 200) # 0 means that request was canceled
              @set 'cancel', null
              if @importResponse(resp.data, resp.status) == WORK_ENTRIES_WHOLE_PAGE
                pageLoad page + 1
                return
              res = DSDigest.block (=> @finalizeLoad())
              if typeof res == 'object' && res != null && 'then' of res # it's promise
                res.then => @_endLoad true; return
              else
                @_endLoad true
            else onError(resp, resp.status == 0)
            return), onError))(1)

      return)

    @end())]
