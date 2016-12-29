module.exports = (ngModule = angular.module 'data/TasksWithTimeTracking', [
]).name

assert = require('../../dscommon/util').assert
error = require('../../dscommon/util').error

DSSet = require '../../dscommon/DSSet'
DSTags = require '../../dscommon/DSTags'
DSData = require '../../dscommon/DSData'
DSDigest = require '../../dscommon/DSDigest'
DSDataServiceBase = require '../../dscommon/DSDataServiceBase'

Task = require '../models/Task'
TaskTimeTracking = require '../models/TaskTimeTracking'

ngModule.factory 'TasksWithTimeTracking', [
  'DSDataSource', '$rootScope', '$http', '$q',
  ((DSDataSource, $rootScope, $http, $q) ->

    return class TasksWithTimeTracking extends DSData

      @begin 'TasksWithTimeTracking'

      @addPool()

      @propDoc 'srcTasks', DSSet
      @propDoc 'srcTasksTimeTracking', DSSet

      @propObj 'cancel', init: null

      @propSet 'tasks', Task

      @ds_dstr.push (->
        cancel.resolve() if cancel = @get('cancel')
        @__unwatchA?()
        @__unwatchB?()
        return)

      clear: (->
        DSData::clear.call @
        cancel.resolve() if cancel = @get('cancel')
        return)

      init: ((dsDataService) ->
        if assert
          error.invalidArg 'dsDataService' if !(dsDataService instanceof DSDataServiceBase)

        (srcTasks = @set 'srcTasks', dsDataService.findDataSet @, {mode: 'original', type: Task, filter: 'all', source: true}).release @

        (srcTasksTimeTracking = @set 'srcTasksTimeTracking', dsDataService.findDataSet @, {mode: 'original', type: TaskTimeTracking}).release @

        tasks = @get 'tasksSet'

        @__unwatchA = srcTasks.watch @,
          add: ((task) ->
            if task.get('timeTracking') == null
              if (ttt = TaskTimeTracking.pool.find @, task.$ds_key)
                task.set 'timeTracking', ttt
                ttt.release @
            tasks.add @, task.addRef @
            return)
          remove: ((task) ->
            tasks.remove task
            return)

        @__unwatchB = srcTasks.watchStatus @, ((source, status) =>
          @set 'status', status
          return)

        @init = null
        return)

      @end())]