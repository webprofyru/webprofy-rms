module.exports = (ngModule = angular.module 'data/teamwork/TWTaskLists', [
  require '../../../dscommon/DSDataSource'
  require './DSDataTeamworkPaged'
]).name

assert = require('../../../dscommon/util').assert
error = require('../../../dscommon/util').error

Project = require '../../models/Project'
TaskList = require '../../models/TaskList'

serviceOwner = require('../../../dscommon/util').serviceOwner

ngModule.factory 'TWTaskLists', ['DSDataTeamworkPaged', 'DSDataSource', '$rootScope', '$q', ((DSDataTeamworkPaged, DSDataSource, $rootScope, $q) ->

  return class TWTaskLists extends DSDataTeamworkPaged

    @begin 'TWTaskLists'

    @addPool()

    @propSet 'taskLists', TaskList
    @propDoc 'project', Project

    @ds_dstr.push (->
      @__unwatch2()
      return)

    init: ((dsDataService) ->
      if @get('params').hasOwnProperty('project')
        @set 'project', project = @get('params').project
        @set 'request', "projects/#{@project.get('id')}/tasklists.json"
      @__unwatch2 = DSDataSource.setLoadAndRefresh.call @, dsDataService
      @init = null
      return)

    startLoad: ->

      @taskListsMap = {}

    importResponse: (json) ->

      cnt = 0

      project = @get 'project'

      for jsonTaskList in json['tasklists']

        ++cnt

        taskList = TaskList.pool.find @, "#{jsonTaskList['id']}", @taskListsMap

        taskList.set 'id', parseInt jsonTaskList['id']
        taskList.set 'name', jsonTaskList['name']
        taskList.set 'project', project
        taskList.set 'position', jsonTaskList['position']

      cnt

    finalizeLoad: ->
      @get('taskListsSet').merge @, @taskListsMap
      delete @taskListsMap
      return

    @loadTaskListsAndProjects = (dataSource, load) ->
      deferred = $q.defer()
      unless load.hasOwnProperty('TaskList')
        deferred.resolve()
      else
        (nextTaskList = ->
          for taskListKey, loadList of load.TaskList
            onError = (error, isCancelled) ->
              if !isCancelled
                console.error 'error: ', error
                delete load.TaskList[taskListKey]
                nextTaskList()
              else deferred.resolve()
              return
            dataSource.httpGet "/tasklists/#{taskListKey}.json", $q.defer()
            .then(((resp) ->
              if (resp.status == 200) # 0 means that request was canceled
                jsonTaskList = resp.data['todo-list']

                project = Project.pool.find serviceOwner, jsonTaskList['projectId']
                project.set 'id', parseInt jsonTaskList['projectId']
                project.set 'name', jsonTaskList['projectName']

                taskList = TaskList.pool.find serviceOwner, taskListKey
                taskList.set 'id', parseInt jsonTaskList['id']
                taskList.set 'name', jsonTaskList['name']
                taskList.set 'project', project
                taskList.set 'position', jsonTaskList['position']

                f(taskList) for f in loadList

                project.release serviceOwner
                taskList.release serviceOwner

                delete load.TaskList[taskListKey]
                nextTaskList()
              else onError(resp, resp.status == 0)
              return), onError)
            return
          for projectKey, loadList of load.Project
            project = Project.pool.find serviceOwner, projectKey
            f(project) for f in loadList
            project.release serviceOwner
          deferred.resolve()
          return)() # nextTaskList = ->
      deferred.promise # loadTaskListsAndProjects:

    @end())]
