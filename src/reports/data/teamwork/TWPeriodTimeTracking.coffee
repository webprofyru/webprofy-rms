module.exports = (ngModule = angular.module 'data/teamwork/TWPeriodTimeTracking', [
  require '../../../dscommon/DSDataSource'
]).name

assert = require('../../../dscommon/util').assert
error = require('../../../dscommon/util').error

DSObject = require '../../../dscommon/DSObject'
DSData = require '../../../dscommon/DSData'
DSSet = require '../../../dscommon/DSSet'
DSDigest = require '../../../dscommon/DSDigest'

Person = require '../../../app/models/Person'
Project = require '../../../app/models/Project'
PeriodTimeTracking = require '../../models/PeriodTimeTracking'

WORK_ENTRIES_WHOLE_PAGE = 500
HISTORY_END_SEARCH_STEP = 50 # how many pages are added at once to the end to find out border of a current history

ngModule.factory 'TWPeriodTimeTracking', [
  'DSDataSource', '$rootScope', '$q',
  (DSDataSource, $rootScope, $q) ->

    class TWPeriodTimeTracking extends DSData

      @begin 'LoadPeriodTimeTracking'

      @addPool()

      @propDoc 'source', DSDataSource

      @propDoc 'people', DSSet
      @propDoc 'projects', DSSet

      @propSet 'timeTracking', PeriodTimeTracking

      @propObj 'cancel', init: null

      @ds_dstr.push ->
        @__unwatchA()
        @__unwatch1()
        @__unwatch2()
        return

      clear: ->
        @__unwatch1?(); @__unwatchA = null
        @__unwatch2?(); @__unwatchB = null
        DSData::clear.call @
        cancel.resolve() if cancel = @get('cancel')
        return # clear

      init: (dsDataService) ->

        throw new Error 'Missing params.from' unless moment.isMoment (from = @get('params').from)
        throw new Error 'Missing params.to' unless moment.isMoment (to = @get('params').to)
        throw new Error 'Params.to is less or equal to params.from' unless from < to

        (@set 'people', dsDataService.findDataSet @, type: Person, mode: 'original').release @
        (@set 'projects', dsDataService.findDataSet @, type: Project, mode: 'original').release @

        @__unwatchA = DSDataSource.setLoadAndRefresh.call @, dsDataService
        @init = null
        return # init:

      # Logic of time tracking load is taken from src/app/data/teamwork/TWTimeTracking.coffee
      load: ->
        if assert
          throw new Error 'load(): Source is not specified' if !@get('source')

        return if !@_startLoad()

        sets = [people = @get('people'), projects = @get('projects')]

# This data for reports only, so it does not maintain isReady, which is primarily necessary for interactive data loads and updates
#        for taskKey, taskTracking of TaskTimeTracking.pool.items # clear up previouse info
#          taskTracking.set 'isReady', false

        actualLoad = =>

          return unless DSObject.integratedStatus(sets) == 'ready'

          @__unwatch1()
          @__unwatch2()

          for personKey, taskTracking of PeriodTimeTracking.pool.items # clear up previouse info
            taskTracking.set 'totalMin', 0

          periodTimeTrackingMap = {}
          missingPeople = {}

          from = @get('params').from
          to = @get('params').to

          importResponse = (timeEntries) =>

            for jsonTaskTimeEntry in timeEntries when (date = moment(jsonTaskTimeEntry['date'])) >= from

              timeEntryId = jsonTaskTimeEntry['id']
              personId = parseInt jsonTaskTimeEntry['person-id']
              projectId = parseInt jsonTaskTimeEntry['project-id']
              minutes = 60 * parseInt(jsonTaskTimeEntry['hours']) + parseInt(jsonTaskTimeEntry['minutes'])

              # Attn: Some reports are not assigned to specific task.
              if jsonTaskTimeEntry['todo-item-id'] != ''
                taskId = parseInt jsonTaskTimeEntry['todo-item-id']
                taskName = jsonTaskTimeEntry['todo-item-name']
              else
                taskId = null
                taskName = null

              if date >= to
                return false # we've reached the end of interesting period

              periodTimeTracking = PeriodTimeTracking.pool.find @, "#{personId}-#{projectId}-#{taskId}", periodTimeTrackingMap
              if not (person = people.items[personId])
                person = Person.pool.find @, "missing-#{personId}", missingPeople
                person.set 'id', personId
                person.set 'missing', true
              periodTimeTracking.set 'person', person
              periodTimeTracking.set 'project', projects.items[projectId]
              periodTimeTracking.set 'taskId', taskId
              periodTimeTracking.set 'taskName', taskName
              periodTimeTracking.set 'totalMin', periodTimeTracking.get('totalMin') + minutes
              periodTimeTracking.set 'lastReport', date

            return timeEntries.length == WORK_ENTRIES_WHOLE_PAGE

          finalizeLoad = (=>
            @get('timeTrackingSet').merge @, periodTimeTrackingMap
            for k, person of missingPeople
              person.release @
            @_endLoad true
            return)

          onError = ((error, isCancelled) => # error
            if !isCancelled
              console.error 'error: ', error
              @set 'cancel', null
            v.release @ for k, v of periodTimeTrackingMap
            @_endLoad false
            return)

          pages = {} # pages cached while looking for a first page

          pageLoad = ((page) =>
            if pages.hasOwnProperty page
              if DSDigest.block (-> importResponse(pages[page]))
                pageLoad page + 1 # load next page
              else # finilize loading
                finalizeLoad()
            else
              @get('source').httpGet("time_entries.json?page=#{page}&pageSize=#{WORK_ENTRIES_WHOLE_PAGE}", @set('cancel', $q.defer()))
              .then(((resp) => # ok
                  if (resp.status == 200) # 0 means that request was canceled
                    @set 'cancel', null
                    if !(entries = resp.data['time-entries']) # empty page
                      finalizeLoad()
                    else if moment(entries[entries.length - 1]['date']) < from # whole page is no interesting already
                      if entries.length == WORK_ENTRIES_WHOLE_PAGE
                        pageLoad page + 1 # load next page
                      else
                        finalizeLoad()
                    else if DSDigest.block (-> importResponse(entries)) # whole page, so try take next one
                      pageLoad page + 1 # load next page
                    else
                      finalizeLoad()
                  else onError(resp, resp.status == 0)
                  return), onError)
            return)

          # Only load history starting from 'from' moment.  Uses dihatomy to find out first interesting page of data
          topPage = 1
          endPage = HISTORY_END_SEARCH_STEP

          (findFirstPage = ((page) =>
            @get('source').httpGet("time_entries.json?page=#{page}&pageSize=#{WORK_ENTRIES_WHOLE_PAGE}", @set('cancel', $q.defer()))
            .then(((resp) => # ok
                if (resp.status == 200) # 0 means that request was canceled
                  @set 'cancel', null
                  if !(entries = resp.data['time-entries']) || entries.length == 0
                    findFirstPage topPage + Math.floor(((endPage = page) - topPage) / 2)
                  else
                    if moment(entries[0]['date']) >= from
                      if topPage == page # found
                        config.set 'histStart', page
                        if (DSDigest.block (-> importResponse(entries)))
                          pageLoad page + 1
                        else
                          finalizeLoad()
                      else
                        pages[page] = entries
                        findFirstPage topPage + Math.floor(((endPage = page) - topPage) / 2)
                    else if moment(entries[entries.length - 1]['date']) < from
                      if endPage == page # move interval up by step
                        [topPage, endPage] = [endPage, endPage + HISTORY_END_SEARCH_STEP]
                        findFirstPage endPage
                      else if endPage == (page + 1) # all data is below 'from'
                        finalizeLoad()
                      else
                        topPage = page + 1
                        findFirstPage topPage + Math.floor((endPage - topPage) / 2)
                    else # found
                      if (DSDigest.block (-> importResponse(entries)))
                        pageLoad page + 1
                      else
                        finalizeLoad()
                else onError(resp, resp.status == 0)
                return), onError)
            return))(endPage)
          return # actualLoad

        @__unwatch1 = people.watchStatus @, actualLoad
        @__unwatch2 = projects.watchStatus @, actualLoad

        return # load

      @end()]
