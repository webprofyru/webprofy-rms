module.exports = (ngModule = angular.module 'ui/views/view2/View2', [
  require '../../../data/dsChanges'
  require '../../../data/dsDataService'
  require '../../../../dscommon/DSView'
  require '../view1/View1'
  require '../../tasks/addCommentAndSave'
  require '../../../data/teamwork/TWTasks'
]).name

assert = require('../../../../dscommon/util').assert

DSDigest = require '../../../../dscommon/DSDigest'

# Global models
Task = require('../../../models/Task')

# View specific models
TaskView = require('../view1/models/TaskView')

ngModule.controller 'View2', ['$scope', 'View2', (($scope, View2) ->
  $scope.view = new View2 $scope, 'view2'
  $scope.tasksHeight = ((row)->
    return '' if !row.expand || _.isEmpty row.tasks
    return "height:#{52 * _.maxBy(row.tasks, 'y').y + 100}px")
  return)]

ngModule.factory 'View2', ['View1', 'DSView', '$rootScope', '$log', 'TWTasks', ((View1, DSView, $rootScope, $log, TWTasks) ->

  return class View2 extends DSView
    @begin 'View2'

    @propData 'tasksOverdue', Task, {filter: 'overdue', watch: ['duedate', 'plan', 'estimate', 'priority']}
    @propData 'tasksNotAssigned', Task, {filter: 'notassigned', watch: ['duedate', 'split', 'plan', 'estimate', 'priority']}

    @propList 'tasksOverdue', Task

    @propPool 'poolTasksNotassignedViews', TaskView
    @propList 'tasksNotAssigned', TaskView
    @propNum  'tasksNotAssignedHeight', init: 0

    @propNum 'renderVer', 0

    @ds_dstr.push (->
      @__unwatchA()
      return)

    constructor: (($scope, key) ->
      DSView.call @, $scope, key

      @__unwatchA = $scope.$watch (-> [
          $scope.$parent.view.startDate?.valueOf(),
          $scope.mode,
          $scope.selectedManager?.$ds_key]),
        (([startDateVal, mode, selectedManager]) =>
          @dataUpdate
            startDate: moment(startDateVal)
            endDate: moment(startDateVal).add(6, 'days')
            mode: mode
            manager: if selectedManager then selectedManager else null
          return), true

      return)

    taskViewsSortRule = (leftView, rightView) ->
      leftTask = leftView.get('task')
      rightTask = rightView.get('task')
      TWTasks.tasksSortRule leftTask, rightTask

    render: (->
      startDate = @__scope.$parent.view.startDate

      if !((status = @get('data').get('tasksOverdueStatus')) == 'ready' || status == 'update')
        @get('tasksOverdueList').merge @, []
      else
        tasksOverdue = _.map @get('data').get('tasksOverdue'), ((task) => task.addRef @; return task)
        tasksOverdue.sort TWTasks.tasksSortRule
        @get('tasksOverdueList').merge @, tasksOverdue

      unless (status = @get('data').get('tasksNotAssignedStatus')) == 'ready' || status == 'update'
        @get('tasksNotAssignedList').merge @, []
        @set 'tasksNotAssignedHeight', 0
      else
        poolTasksNotassignedViews = @get('poolTasksNotassignedViews')
        tasksNotAssigned = @get('tasksNotAssignedList').merge @, (_.map @get('data').get('tasksNotAssigned'), (task) =>
          taskView = poolTasksNotassignedViews.find @, task.$ds_key
          taskView.set 'task', task
          return taskView).sort taskViewsSortRule
        @set 'tasksNotAssignedHeight', View1.layoutTaskView startDate, tasksNotAssigned

      @set 'renderVer', (@get('renderVer') + 1)

      return)

    @end())]

ngModule.directive 'rmsView2DayDropTask', [
  'dsChanges', '$rootScope', 'addCommentAndSave', 'getDropTasksGroup',
  (dsChanges, $rootScope, addCommentAndSave, getDropTasksGroup) -> # () ->
    restrict: 'A'
    scope: true
    link: ($scope, element, attrs) ->

      el = element[0]

      getDay = (ev) ->
        day = _.findIndex $('.vertical-lines > .col', element), (zone) ->
          $v = $(zone)
          $v.offset().left + $v.width() >= ev.clientX # (zone) ->
        if -1 <= --day <= 6 then day else -2

      el.addEventListener 'dragover', (ev) ->
        return false if getDay(ev) == -2
        ev.preventDefault()
        true # (ev) ->

      el.addEventListener 'drop', (ev) ->

        if ev.dataTransfer.getData('task')
          day = getDay(ev)
          unless ev.ctrlKey && !(modal = $rootScope.modal).task.split && modal.task.duedate != null
            tasks = [$rootScope.modal.task]
          else # group movement, if task has no split and 'ctrl' key is pressed while operation
            tasks = getDropTasksGroup()
          addCommentAndSave tasks, ev.shiftKey, # You have to keep shift, if you need to make a comment
            responsible: null
            duedate: if day == -1 then null else $scope.view1.get('days')[day].get('date')
            plan: false

        $rootScope.$digest()
        ev.stopPropagation()
        false # (ev) ->

      return] # link:
