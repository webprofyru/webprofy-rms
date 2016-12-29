module.exports = (ngModule = angular.module 'data/dsDataService', [
  require './PeopleWithJson'
  require './TasksWithTimeTracking'
  require './teamwork/TWPeople'
  require './teamwork/TWProjects'
  require './teamwork/TWTaskLists'
  require './teamwork/TWTasks'
  require './teamwork/TWTags'
  require './teamwork/TWTimeTracking'
  require './PersonDayStatData'
  require './dsChanges'
  require '../../dscommon/DSDataSource'
  require '../config'
]).name

assert = require('../../dscommon/util').assert
serviceOwner = require('../../dscommon/util').serviceOwner
error = require('../../dscommon/util').error

base64 = require '../../utils/base64'

DSObject = require '../../dscommon/DSObject'
DSDataServiceBase = require '../../dscommon/DSDataServiceBase'
DSChangesBase = require '../../dscommon/DSChangesBase'
DSDataEditable = require '../../dscommon/DSDataEditable'
DSDataFiltered = require '../../dscommon/DSDataFiltered'

Person = require '../models/Person'
Tag = require '../models/Tag'
Task = require '../models/Task'
TaskTimeTracking = require '../models/TaskTimeTracking'
PersonTimeTracking = require '../models/PersonTimeTracking'

ngModule.run ['dsDataService', '$rootScope', ((dsDataService, $rootScope) ->
  $rootScope.dataService = dsDataService
  return)]

ngModule.factory 'dsDataService', [
 'TWPeople', 'TWTasks', 'TWProjects', 'TWTaskLists', 'TWTags', 'TWTimeTracking', 'PeopleWithJson', 'TasksWithTimeTracking', 'PersonDayStatData', 'DSDataSource', 'dsChanges', 'config', '$http', '$rootScope', '$q',
 ((TWPeople, TWTasks, TWProjects, TWTaskLists, TWTags, TWTimeTracking, PeopleWithJson, TasksWithTimeTracking, PersonDayStatData, DSDataSource, dsChanges, config, $http, $rootScope, $q) ->

    class DSDataService extends DSDataServiceBase
      @begin 'DSDataService'

      @propDoc 'dataSource', DSDataSource

      @propPool 'editedPeople', DSDataEditable(Person.Editable)
      @propPool 'editedTasks', DSDataEditable(Task.Editable)

      @propPool 'tasksPool', DSDataFiltered(Task)
      @propPool 'personTimeTrackingPool', DSDataFiltered(PersonTimeTracking)

      @propBool 'showTimeSpent', init: false

      @propDoc 'changes', DSChangesBase

      @propSet 'emptyPersonTimeTracking', PersonTimeTracking

      @ds_dstr.push (->
        @__unwatch2()
        return)

      constructor: (->
        DSDataServiceBase.apply @, arguments
        (@set 'dataSource', new DSDataSource(@, 'dataSource')).release @

        cancel = null
        @__unwatch2 = $rootScope.$watch (-> [config.get('teamwork'), config.get('token')]), (([teamwork, token]) =>

          if !(teamwork && token)
            $rootScope.connected = false
            @get('dataSource').setConnection(null, null)
          else
            (cancel.resolve(); cancel = null) if cancel

            onError = ((error, isCancelled) =>
              $rootScope.connected = false
              if !isCancelled
                console.error 'error: ', error
                cancel = null
              @get('dataSource').setConnection(null, null)
              return)

            $rootScope.connected = null
            $http.get "#{teamwork}authenticate.json",
              timeout: (cancel = $q.defer()).promise
              headers: {Authorization: "Basic #{base64.encode(token)}"}
            .then ((resp) =>
              if (resp.status == 200) # 0 means that request was canceled
                $rootScope.connected = true
                cancel = null
                config.set 'currentUserId', resp.data['account']['userId']
                @get('dataSource').setConnection(teamwork, token)
              else onError(resp, resp.status == 0)
              return), onError

            return), true

        (@set 'changes', dsChanges).init @

        return)

      refresh: (->
        @get('dataSource').refresh()
        return)

      findDataSet: ((owner, params) ->
        DSDataServiceBase::findDataSet.call @, owner, params

        switch params.type.docType
          when 'Tag'
            (data = TWTags.pool.find @, {}).init? @
            (set = data.get('tagsSet')).addRef owner; data.release @
            return set
          when 'PersonDayStat'
            (data = PersonDayStatData.pool.find @, params).init? @
            (set = data.get('personDayStatsSet')).addRef owner; data.release @
            return set
          when 'TaskTimeTracking'
            if (data = TWTimeTracking.pool.find(@, {})).init then data.init @
            (set = data.get('taskTimeTrackingSet')).addRef owner; data.release @
            return set
          when 'PersonTimeTracking'
            if params.hasOwnProperty('showTimeSpent') && !params.showTimeSpent
              (set = @get('emptyPersonTimeTrackingSet')).addRef owner;
            else if !params.hasOwnProperty('startDate')
              if (data = TWTimeTracking.pool.find(@, {})).init then data.init @
              (set = data.get('personTimeTrackingSet')).addRef owner; data.release @
            else
              if (data = @get('personTimeTrackingPool').find(@, params)).init
                data.init(
                  originalSet = @findDataSet @, {type: PersonTimeTracking, mode: params.mode}
                  TWTimeTracking.filterPersonTimeTracking(params))
                originalSet.release @
              (set = data.get('itemsSet')).addRef owner; data.release @
            return set

        switch params.mode
          when 'edited'
            switch (type = params.type.docType)
              when 'Person'
                return @findDataSet owner, _.assign({}, params, {mode: 'original'})
              when 'Task'
                if (data = @get('editedTasks').find(@, params)).init
                  data.init(
                    originalSet = @findDataSet @, _.assign({}, params, {mode:'original'})
                    changesSet = @findDataSet @, _.assign({}, params, {mode:'changes'})
                    TWTasks.filter(params))
                  originalSet.release @
                  changesSet.release @
                (set = data.get('itemsSet')).addRef owner; data.release @
                return set
              else
                throw new Error "Not supported model type (1): #{type}"
          when 'changes'
            switch (type = params.type.docType)
              when 'Task'
                return (set = @get('changes').get('tasksSet')).addRef owner
              else
                throw new Error "Not supported model type (2): #{type}"
          when 'original'
            switch (if (type = params.type) != Person then type.docType else if !config.get('hasRoles') || params.source then Person.docType else 'PeopleWithJson')
              when 'PeopleWithJson'
                (data = PeopleWithJson.pool.find(@, params)).init? @
                (set = data.get('peopleSet')).addRef owner; data.release @
                return set
              when 'Person'
                delete params.source
                (data = TWPeople.pool.find(@, params)).init? @
                (set = data.get('peopleSet')).addRef owner; data.release @
                return set
              when 'Project'
                delete params.source
                (data = TWProjects.pool.find(@, params)).init? @
                (set = data.get('projectsSet')).addRef owner; data.release @
                return set
              when 'TaskList'
                delete params.source
                (data = TWTaskLists.pool.find(@, params)).init? @
                (set = data.get('taskListsSet')).addRef owner; data.release @
                return set
              when 'Task'
# Version 2 - request all non-completed tasks at once.  This resolves plenty of issues
                if params.filter == 'all' && !params.hasOwnProperty('startDate')
                  if !config.get('hasTimeReports') || params.source
                    delete params.source
                    (data = TWTasks.pool.find(@, params)).init? @
                  else # it's extra DSData that links Task and TaskTimeTracking
                    if (data = TasksWithTimeTracking.pool.find(@, {})).init then data.init @
                  (set = data.get('tasksSet')).addRef owner; data.release @
                else
                  if (data = @get('tasksPool').find(@, params)).init
                    data.init(
                      originalSet = @findDataSet @, {type: Task, mode: 'original', filter: 'all'}
                      TWTasks.filter(params))
                    originalSet.release @
                  (set = data.get('itemsSet')).addRef owner; data.release @
                return set
# Version 1 - week by week teamwork requests
#                (data = TWTasks.pool.find(@, params)).init? @
#                (set = data.get('tasksSet')).addRef owner; data.release @
#                return set
              else
                throw new Error "Not supported model type (3): #{type}"
        return)

      requestSources: ((owner, params, sources) ->
        DSDataServiceBase::requestSources.call @, owner, params, sources
        # Process request, if source should not be changed then returns already existing one
        # Relese sources that were replaced
        for k, v of sources
          srcParams = _.assign {}, v.params, params
          requestParams = {type: type = v.type, mode: mode = srcParams.mode}
          switch (docType = type.docType)
            when 'Tag', 'Person', 'Project'
              undefined
            when 'TaskList'
              requestParams.project = srcParams.project
            when 'PersonDayStat'
              requestParams.startDate = srcParams.startDate
              requestParams.endDate = srcParams.endDate
            when 'PersonTimeTracking'
              requestParams.showTimeSpent = srcParams.showTimeSpent
              requestParams.startDate = srcParams.startDate
              requestParams.endDate = srcParams.endDate
            when 'Task'
              if mode != 'changes'
                if assert
                  if !(typeof srcParams.filter == 'string' && 0 <= ['all', 'assigned', 'notassigned', 'overdue', 'noduedate', 'clipboard'].indexOf(srcParams.filter))
                    throw new Error "Unexpected filter: #{srcParams.filter}"
                requestParams.filter = srcParams.filter
                if srcParams.filter == 'all' || srcParams.filter == 'assigned' || srcParams.filter == 'notassigned'
                  requestParams.startDate = srcParams.startDate
                  requestParams.endDate = srcParams.endDate
                if srcParams.manager
                  requestParams.manager = srcParams.manager
            else
              throw new Error "Not supported model type (4): #{docType}"
          newSet = @findDataSet owner, requestParams
          if typeof (set = v.set) == 'undefined' || set != newSet
            v.newSet = newSet
          else
            newSet.release owner
        return)

      @end()

    return serviceOwner.add(new DSDataService serviceOwner, 'dataService'))]
