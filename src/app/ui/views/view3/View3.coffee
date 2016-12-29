module.exports = (ngModule = angular.module 'ui/views/view3/View3', [
  require '../../../config'
  require '../../../data/dsDataService'
  require('../../../../dscommon/DSView')
  require '../../tasks/addCommentAndSave'
  require '../../../data/teamwork/TWTasks'
]).name

assert = require('../../../../dscommon/util').assert
error = require('../../../../dscommon/util').error

# Global models
Task = require('../../../models/Task')
TaskList = require('../../../models/TaskList')
Project = require('../../../models/Project')

# View specific models
PersonView = require('./models/PersonView')
ProjectView = require('./models/ProjectView')
TaskListView = require('./models/TaskListView')
Row = require('../view1/models/Row')

ngModule.controller 'View3', [
  '$scope', 'View3',
  ($scope, View3) ->
    $scope.view = new View3 $scope, 'view3'
    return]

ngModule.factory 'View3', [
  'DSView', 'config', '$rootScope', '$log', 'TWTasks',
  (DSView, config, $rootScope, $log, TWTasks) ->

    class View3 extends DSView # () ->
      @begin 'View3'

      @propData 'tasks', Task, {watch: ['duedate', 'priority', 'clipboard']}

      @propPool 'poolPeople', PersonView
      @propList 'people', PersonView

      @propPool 'poolProjects', ProjectView
      @propList 'projects', ProjectView

      @ds_dstr.push (->
        @__unwatchA()
        @__unwatchB?()
        @__unwatchС()
        @__unwatchD?()
        clearTimeout @__timer1
        return)

      constructor: ($scope, key) ->
        DSView.call @, $scope, key

        @scope = $scope

        @expandedProj = {}
        @expandedRows = {}

        @__unwatchA = $scope.$watch (-> [$scope.mode, config.activeSidebarTab, $scope.selectedManager?.$ds_key]),
          (([mode, active, selectedManager]) =>
            $rootScope.view3ActiveTab = active
            selectedManager = null unless selectedManager
            switch active
              when -1 # clipboard
                @__unwatchB?()
                @dataUpdate {filter: 'clipboard', mode, manager: selectedManager}
              when 0 # no duedate
                @__unwatchB?()
                @dataUpdate {filter: 'noduedate', mode, manager: selectedManager}
              when 1 # next week
                @__unwatchB = $scope.$watch (-> $scope.$parent.view.startDate?.valueOf()), (startDateVal) =>
                  $rootScope.startDateVal = startDateVal
                  if typeof startDateVal != 'number'
                    config.activeSidebarTab = 0
                  else
                    nextWeekStartDate = moment(startDateVal).add 1, 'week'
                    nextWeekEndDate = moment(nextWeekStartDate).endOf 'week'
                    @dataUpdate {filter: 'all', mode, startDate: nextWeekStartDate, endDate: nextWeekEndDate, manager: selectedManager}
                  return
              when 2 # all tasks by project
                @__unwatchB?()
                @dataUpdate {filter: 'all', mode, manager: selectedManager}
            return), true

        @__unwatchC = $scope.$watch (-> [config.view3GroupByPerson, config.view3HidePeopleWOTasks, config.view3FilterByPerson, config.view3FilterByProject, config.view3FilterByTask]), (=>
          clearTimeout @__timer1
          @__timer1 = setTimeout (=> @__dirty++; $scope.$digest(); return), 300
          return), true

        $scope.notAssignedExpanded = true

        $scope.toggleProjectExpanded = (project) =>
          if assert
            error.invalidArg 'project' if !(project instanceof ProjectView)
          viewExpandedProj = if !(expandedProj = @expandedProj).hasOwnProperty (active = config.activeSidebarTab)
              expandedProj[active] = viewExpandedProject = {}
            else expandedProj[active]
          if viewExpandedProj.hasOwnProperty(projectKey = project.$ds_key)
              viewExpandedProj[projectKey] = !viewExpandedProj[projectKey]
            else viewExpandedProj[projectKey] = !(active != 2) # 2 - all by project

        $scope.isProjectExpanded = (project) =>
          if assert
            error.invalidArg 'project' if !(project instanceof ProjectView)
          if (expandedProj = @expandedProj).hasOwnProperty (active = config.activeSidebarTab)
            if (viewExpandedProj = expandedProj[active]).hasOwnProperty(projectKey = project.$ds_key)
              return viewExpandedProj[projectKey]
          active != 2 # 2 - all by project

        $scope.togglePersonExpanded = (personView) =>
          if assert
            error.invalidArg 'personView' if !(personView instanceof PersonView)
          viewExpandedRows = if !(expandedRows = @expandedRows).hasOwnProperty (active = config.activeSidebarTab)
            expandedRows[active] = viewExpandedRowsect = {}
          else expandedRows[active]
          if viewExpandedRows.hasOwnProperty(personKey = personView.$ds_key)
            viewExpandedRows[personKey] = !viewExpandedRows[personKey]
          else viewExpandedRows[personKey] = false

        $scope.isPersonExpended = (personView) =>
          if assert
            error.invalidArg 'personView' if !(personView instanceof PersonView)
          if (expandedRows = @expandedRows).hasOwnProperty (active = config.activeSidebarTab)
            if (viewExpandedRows = expandedRows[active]).hasOwnProperty(personKey = personView.$ds_key)
              return viewExpandedRows[personKey]
          true

      filterPerson = (row, filterByPerson) ->
        if row == 'null'
          'not assigned tasks'.indexOf(filterByPerson) >= 0
        else
          row.person.name.toLowerCase().indexOf(filterByPerson) >= 0 ||
          row.person.firstName.toLowerCase().indexOf(filterByPerson) >= 0 ||
          row.person.email.toLowerCase().indexOf(filterByPerson) >= 0

      render: ->

        if !((status = @get('data').get('tasksStatus')) == 'ready' || status == 'update')
          @get('projectsList').merge @, []
          return

        tasks = @get('data').get('tasks')
        if (filterByTask = config.view3FilterByTask)?.length > 0
          filterByTask = filterByTask.trim().toLowerCase()
          tasks = _.filter tasks, ((task) -> task.get('title').toLowerCase().indexOf(filterByTask) >= 0)

        if config.view3GroupByPerson == 0

          tasksByTaskList = _.groupBy tasks, ((task) -> task.get('taskList').$ds_key)
          tasksByProject = _.groupBy tasksByTaskList, ((taskList) -> taskList[0].get('project').$ds_key)

          if (filterByProject = config.view3FilterByProject)?.length > 0
            filterByProject = filterByProject.trim().toLowerCase()
            for k, v of tasksByProject when not (Project.pool.items[k].get('name').toLowerCase().indexOf(filterByProject) >= 0)
              delete tasksByProject[k]

          poolProjects = @get 'poolProjects'
          projects = @get('projectsList').merge @, (_.map tasksByProject, ((projectGroup, projectKey) =>
            projectView = poolProjects.find @, projectKey
            projectView.set 'project', Project.pool.items[projectKey]
            projectView.get('taskListsList').merge @, _.map projectGroup, ((taskListGroup) =>
              taskListKey = taskListGroup[0].get('taskList').$ds_key
              taskListView = projectView.poolTaskLists.find @, taskListKey
              taskListView.set 'taskList', TaskList.pool.items[taskListKey]
              taskListView.set 'tasksCount', _.size taskListGroup
              taskListView.set 'totalEstimate', _.reduce taskListGroup, ((sum, task) -> if (estimate = task.get('estimate')) then sum.add estimate else sum), moment.duration(0)
              taskListView.get('tasksList').merge @, (_.map taskListGroup, ((task) => task.addRef @)).sort TWTasks.tasksSortRule
              return taskListView)
            return projectView)).sort ((left, right) ->
              if (leftLC = left.get('project').get('name').toLowerCase()) < (rightLC = right.get('project').get('name').toLowerCase()) then -1 else if leftLC > rightLC then 1 else 0)

          @get('peopleList').merge @, []
          if @__unwatchD
            (@__unwatchD(); @__unwatchD = null)
            @__src.tasks.watch.length = @__src.tasks.watch.length - 1 # remove 'responsible'

        else

          unless @__unwatchD
            @__unwatchD = @scope.$watch (=> (r.$ds_key for r in @scope.view1.rows)), ((val, newVal) =>
              if val != newVal
                @__dirty++
              return), true
            @__src.tasks.watch.push 'responsible'

          poolPeople = @get 'poolPeople'

          if (filterByPerson = config.view3FilterByPerson)?.length > 0
            filterByPerson = filterByPerson.trim().toLowerCase()

          if (filterByProject = config.view3FilterByProject)?.length > 0
            filterByProject = filterByProject.trim().toLowerCase()

          tasksByPeople = _.groupBy tasks, (task) -> if (responsible = task.get('responsible')) then responsible.$ds_key else 'null'

          rows = @scope.view1.rows
          rows = rows.concat 'null' if tasksByPeople.hasOwnProperty('null')
          resultRows = []
          for r in rows when !filterByPerson || filterPerson r, filterByPerson

            if tasksByPeople.hasOwnProperty(personViewKey = (if r != 'null' then r.$ds_key else 'null')) # non empty

              tasksByTaskList = _.groupBy tasksByPeople[personViewKey], ((task) -> task.get('taskList').$ds_key)
              tasksByProject = _.groupBy tasksByTaskList, ((taskList) -> taskList[0].get('project').$ds_key)

              if filterByProject
                for k, v of tasksByProject when not (Project.pool.items[k].get('name').toLowerCase().indexOf(filterByProject) >= 0)
                  delete tasksByProject[k]

              continue if Object.keys(tasksByProject).length == 0

              resultRows.push (personView = poolPeople.find @, personViewKey)
              personView.set 'row', r unless r == 'null'

              poolProjects = personView.get 'poolProjects'
              personView.get('projectsList').merge @, (_.map tasksByProject, ((projectGroup, projectKey) =>
                projectView = poolProjects.find @, projectKey
                projectView.set 'project', Project.pool.items[projectKey]
                projectView.get('taskListsList').merge @, _.map projectGroup, ((taskListGroup) =>
                  taskListKey = taskListGroup[0].get('taskList').$ds_key
                  taskListView = projectView.poolTaskLists.find @, taskListKey
                  taskListView.set 'taskList', TaskList.pool.items[taskListKey]
                  taskListView.set 'tasksCount', _.size taskListGroup
                  taskListView.set 'totalEstimate', _.reduce taskListGroup, ((sum, task) -> if (estimate = task.get('estimate')) then sum.add estimate else sum), moment.duration(0)
                  taskListView.get('tasksList').merge @, (_.map taskListGroup, ((task) => task.addRef @)).sort TWTasks.tasksSortRule
                  return taskListView)
                return projectView)).sort ((left, right) ->
                  if (leftLC = left.get('project').get('name').toLowerCase()) < (rightLC = right.get('project').get('name').toLowerCase()) then -1
                  else if leftLC > rightLC then 1 else 0)

            else unless config.get 'view3HidePeopleWOTasks'

              resultRows.push personView = poolPeople.find @, personViewKey
              personView.set 'row', r unless r == 'null'
              personView.get('projectsList').merge @, []

          @get('peopleList').merge @, resultRows
          @get('projectsList').merge @, []

        return # render:

      @end()] # class

ngModule.directive 'rmsView3DropTask', [
  '$rootScope', 'addCommentAndSave', 'getDropTasksGroup',
  ($rootScope, addCommentAndSave, getDropTasksGroup) ->
    restrict: 'A'
    scope: true
    link: ($scope, element, attrs) ->

      el = element[0]

      activeTab = if attrs.rmsView3DropTask.length > 0 then (do (tab = parseInt(attrs.rmsView3DropTask)) -> -> tab) else (-> $rootScope.view3ActiveTab)

      el.addEventListener 'dragover', (ev) ->
        ev.preventDefault()
        activeTab() == 2 # (ev) ->

      el.addEventListener 'drop', (ev) ->

        if ev.dataTransfer.getData('task')

          unless ev.ctrlKey && !(modal = $rootScope.modal).task.split && modal.task.duedate != null
            tasks = [$rootScope.modal.task]
          else # group movement, if task has no split and 'ctrl' key is pressed while operation
            tasks = getDropTasksGroup()

          fields = plan: false
          switch activeTab()
            when -1
              fields.duedate = null
              fields.clipboard = true
            when 0 then fields.duedate = null
            when 1 then fields.duedate = moment($rootScope.startDateVal).add(1, 'week')

          addCommentAndSave tasks, ev.shiftKey, fields # You have to keep shift, if you need to make a comment

        $rootScope.$digest()
        ev.stopPropagation()
        return false # (ev) ->

      return # link:
    ] # ($rootScope, addCommentAndSave) ->





