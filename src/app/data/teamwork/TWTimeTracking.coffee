module.exports = (ngModule = angular.module 'data/teamwork/TWTimeTracking', [
  require '../../config'
  require '../../../dscommon/DSDataSource'
  require '../../db'
]).name

assert = require('../../../dscommon/util').assert
error = require('../../../dscommon/util').error

time = require '../../ui/time'

Task = require '../../models/Task'
TaskTimeTracking = require '../../models/TaskTimeTracking'
PersonTimeTracking = require '../../models/PersonTimeTracking'

DSData = require '../../../dscommon/DSData'
DSDigest = require '../../../dscommon/DSDigest'

TaskSplit = require '../../models/types/TaskSplit'
RMSData = require '../../utils/RMSData'

WORK_ENTRIES_WHOLE_PAGE = 500
HISTORY_END_SEARCH_STEP = 50 # how many pages are added at once to the end to find out border of a current history

ngModule.factory 'TWTimeTracking', [
  'DSDataSource', '$q', 'db', 'config',
  ((DSDataSource, $q, db, config) ->

    return class TWTimeTracking extends DSData

      @begin 'TWTimeTracking'

      @addPool()

      @propDoc 'source', DSDataSource

      @propSet 'taskTimeTracking', TaskTimeTracking

      @propSet 'personTimeTracking', PersonTimeTracking

      @propObj 'cancel', null

      @ds_dstr.push (->
        cancel.resolve() if cancel = @get('cancel')
        @__unwatchA?()
        @__unwatchB?()
        return)

      @propObj 'visibleTTracking', init: {}

      constructor: (->
        DSData.apply @, arguments
        if assert
          console.error "TWTimeTracking:ctor: setVisible expects that their will be only one instance of TWTimeTracking object" if TaskTimeTracking::hasOwnProperty('setVisible')
        visibleTTracking = @get('visibleTTracking')
        TaskTimeTracking::setVisible = ((isVisible) ->
          if isVisible
            if (@__visCount = (@__visCount || 0) + 1) == 1 && !@get('isReady')
              visibleTTracking[@$ds_key] = @
              # TODO: Start load the data
          else if --@__visCount == 0
            delete visibleTTracking[@$ds_key]
          return)
        return)

      clear: (->
        DSData::clear.call @
        cancel.resolve() if cancel = @get('cancel')
        @__unwatchB?()
        return)

      @filterPersonTimeTracking = ((params) ->
        return ((personTTracking) -> params.startDate <= moment(personTTracking.get('date').startOf('day')) <= params.endDate))

      init: ((dsDataService) ->
        @__unwatchA = DSDataSource.setLoadAndRefresh.call @, dsDataService
        @init = null
        return)

      load: (->
        if assert
          throw new Error 'load(): Source is not specified' if !@get('source')

        return if !@_startLoad()

        @__unwatchB?()

        PersonTimeTracking.pool.enableWatch false
        TaskTimeTracking.pool.enableWatch false

  # This code is part of commented out Version2 - see below
  #      database = db.openDB()

        for taskKey, taskTracking of TaskTimeTracking.pool.items # clear up previouse info
          taskTracking.set 'isReady', false
          taskTracking.set 'totalMin', 0
          taskTracking.set 'priorTodayMin', 0
          taskTracking.set 'timeEntries', {}

        for personKey, taskTracking of PersonTimeTracking.pool.items # clear up previouse info
          taskTracking.set 'timeMin', 0

        personTimeTrackingMap = {}
        taskTimeTrackingMap = {}

        importResponse = ((timeEntries) =>
          for jsonTaskTimeEntry in timeEntries when moment(jsonTaskTimeEntry['date']) >= time.historyLimit
            continue if !taskId = parseInt(taskIdStr = jsonTaskTimeEntry['todo-item-id']) # it's possible that time entry is not associated with a task
            timeEntryId = jsonTaskTimeEntry['id']
            personId = parseInt(personIdStr = jsonTaskTimeEntry['person-id'])
            minutes = 60 * parseInt(jsonTaskTimeEntry['hours']) + parseInt(jsonTaskTimeEntry['minutes'])
            date = moment(jsonTaskTimeEntry['date']).startOf('day')

            # PersonTimeTracking
            personTimeTracking = PersonTimeTracking.pool.find @, "#{personIdStr}-#{taskId}-#{date.valueOf()}", personTimeTrackingMap
            personTimeTracking.set 'personId', personId
            personTimeTracking.set 'date', date
            personTimeTracking.set 'taskId', taskId
            personTimeTracking.set 'timeMin', personTimeTracking.get('timeMin') + minutes

            # TaskTimeTracking
            if taskTimeTrackingMap.hasOwnProperty(taskIdStr)
              taskTTracking = taskTimeTrackingMap[taskIdStr]
            else
              taskTTracking = TaskTimeTracking.pool.find @, taskIdStr, taskTimeTrackingMap
              taskTTracking.set 'taskId', taskId
            taskTTracking.set 'totalMin', taskTTracking.get('totalMin') + minutes
            taskTTracking.get('timeEntries')[timeEntryId] = true
            if date < time.today
              taskTTracking.set 'priorTodayMin', taskTTracking.get('priorTodayMin') + minutes
          return timeEntries.length == WORK_ENTRIES_WHOLE_PAGE)

        finalizeLoad = (=>
          DSDigest.block (=>
            # Note: We should update all documents within pool
            for taskKey, taskTTracking of TaskTimeTracking.pool.items
              taskTTracking.set 'isReady', true
            if !@__unwatchB # set isReady for all new TaskTimeTracking objects
              @__unwatchB = TaskTimeTracking.pool.watch @, ((taskTTracking) -> taskTTracking.set 'isReady', true; return)
            PersonTimeTracking.pool.enableWatch true
            @get('personTimeTrackingSet').merge @, personTimeTrackingMap
            TaskTimeTracking.pool.enableWatch true
            @get('taskTimeTrackingSet').merge @, taskTimeTrackingMap
            return)
          @_endLoad true
          return)

        onError = ((error, isCancelled) => # error
          if !isCancelled
            console.error 'error: ', error
            @set 'cancel', null
          v.release @ for k, v of taskTimeTrackingMap
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
                if !(entries = resp.data['time-entries']) || entries.length == 0 # empty page
                  finalizeLoad()
                else if moment(entries[entries.length - 1]['date']) < time.historyLimit # whole page is no interesting already
                  config.set 'histStart', page + 1
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

        # Only load history starting from time.historyLimit moment - two previous week.  Uses dihatoьy to find out first interesting page of data
        topPage = 1
        endPage = HISTORY_END_SEARCH_STEP

        if ((histStart = config.get('histStart')) >= 0)
          pageLoad histStart
        else
          (findFirstPage = ((page) =>
            @get('source').httpGet("time_entries.json?page=#{page}&pageSize=#{WORK_ENTRIES_WHOLE_PAGE}", @set('cancel', $q.defer()))
            .then(((resp) => # ok
              if (resp.status == 200) # 0 means that request was canceled
                @set 'cancel', null
                if !(entries = resp.data['time-entries']) || entries.length == 0
                  findFirstPage topPage + Math.floor(((endPage = page) - topPage) / 2)
                else
                  if moment(entries[0]['date']) >= time.historyLimit
                    if topPage == page # found
                      config.set 'histStart', page
                      if (DSDigest.block (-> importResponse(entries)))
                        pageLoad page + 1
                      else
                        finalizeLoad()
                    else
                      pages[page] = entries
                      findFirstPage topPage + Math.floor(((endPage = page) - topPage) / 2)
                  else if moment(entries[entries.length - 1]['date']) < time.historyLimit
                    if endPage == page # move interval up by step
                      [topPage, endPage] = [endPage, endPage + HISTORY_END_SEARCH_STEP]
                      findFirstPage endPage
                    else if endPage == (page + 1) # all data is below time.historyLimit
                      finalizeLoad()
                    else
                      topPage = page + 1
                      findFirstPage topPage + Math.floor((endPage - topPage) / 2)
                  else # found
                    config.set 'histStart', page
                    if (DSDigest.block (-> importResponse(entries)))
                      pageLoad page + 1
                    else
                      finalizeLoad()
              else onError(resp, resp.status == 0)
              return), onError)
            return))(endPage)
        return)

      @end())]
