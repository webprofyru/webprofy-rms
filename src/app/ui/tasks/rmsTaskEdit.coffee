module.exports = (ngModule = angular.module 'ui/tasks/rmsTaskEdit', [
  require '../../data/dsChanges'
  require '../../data/dsDataService'
  require './TaskSplitWeekView'
  require './addCommentAndSave'
]).name

assert = require('../../../dscommon/util').assert

time = require('../../ui/time')

DSDigest = require '../../../dscommon/DSDigest'
DSTags = require '../../../dscommon/DSTags'
DSDataEditable = require('../../../dscommon/DSDataEditable')

Tag = require '../../models/Tag'
Task = require '../../models/Task'
TaskList = require '../../models/TaskList'
Person = require '../../models/Person'
Project = require '../../models/Project'
TaskSplit = require '../../models/types/TaskSplit'
PersonDayStat = require '../../models/PersonDayStat'

Task$u = DSDataEditable(Task.Editable).$u

splitViewWeeksCount = 3

ngModule.directive 'rmsTaskEdit', [
  'TaskSplitWeekView', 'dsDataService', 'dsChanges', 'addCommentAndSave', '$rootScope', '$window', '$timeout',
  ((TaskSplitWeekView, dsDataService, dsChanges, addCommentAndSave, $rootScope, $window, $timeout) ->
    restrict: 'A'
    scope: true
    link: (($scope, element, attrs) ->

      modal = $rootScope.modal

      $scope.edit = edit = {}

      unwatchSplitLastDate = null

      newTaskSplitWeekView = ((monday) ->
        return new TaskSplitWeekView(
          $scope
          "TaskSplitWeekView #{monday.format()}"
          (-> edit.splitDuedate)
          edit.split, monday))

      makeSplitView = (->
        monday = edit.firstWeek
        edit.splitView = (for w in [0...splitViewWeeksCount]
          view = newTaskSplitWeekView monday
          (monday = moment(monday)).add(1, 'week')
          view)
        unwatchSplitLastDate = $scope.$watch (-> edit.split.lastDate(edit.splitDuedate)?.valueOf()), ((lastDateValue) ->
          return if !typeof lastDateValue == 'number'
          edit.split.shift (lastDate = moment(lastDateValue)), edit.splitDuedate
          edit.splitDuedate = lastDate
          return)
        return)

      releaseSplitView = (->
        v.release $scope for v in edit.splitView
        edit.splitView = null
        unwatchSplitLastDate()
        return)

      $scope.$evalAsync (-> $($('input', element)[1]).select(); return)

      $scope.people = _.map Person.pool.items, ((person)-> person)
      $scope.task = task = modal.task
      $scope.$watch (-> time.today.valueOf()), (-> $scope.today = time.today)

      $scope.$on '$destroy', ->
        $scope._unwatch?()
        $scope._unwatch2?()
        $scope._unwatch3?()
        $scope._unwatch4?()
        edit.tags.release $scope if edit.tags && edit.tags != task.get('tags')
        return

      if (edit.newTask = newTask = (task == undefined))
        newTaskValues = $rootScope.newTaskValues
        # TODO: Select documents based on saved IDes
        # TODO: Add project and taskList selectors
        edit.project = newTaskValues?.project || null
        edit.taskList = newTaskValues?.taskList || null
        edit.responsible = newTaskValues?.taskList || null
        edit.title = null
        edit.description = null
        edit.duedate = duedate = if newTaskValues?.duedate then moment(newTaskValues.duedate) else null
        edit.estimate = if newTaskValues?.estimate then moment.duration(newTaskValues.estimate) else null
        edit.tags = if newTaskValues?.tags then new DSTags $scope, newTaskValues.tags else null

        unwatchA = null
        allProjects = dsDataService.findDataSet $scope, type: Project, mode: 'original'
        allProjects.watchStatus $scope, (source, status, prevStatus, unwatch) ->
          # TODO: Select current project
          $scope._unwatch3 = ->
            unwatchA?()
            unwatch()
            allProjects.release $scope
            project.release $scope for project in $scope.projectsList
            $scope.projectsList = null
            return
          return unless status == 'ready'
          unwatch(); $scope._unwatch3 = null
          project.addRef $scope for project in ($scope.projectsList = (project for projectKey, project of allProjects.items).sort (l, r) -> l.get('name').localeCompare(r.get('name')))
          unless unwatchA
            unwatchA = $scope.$watch (-> edit.project?.$ds_key), (projectKey) ->
              $scope.taskListsList = null
              edit.taskList = null
              if projectKey
                if $scope.taskListsList
                  taskList.release $scope for taskList in $scope.taskListsList
                  $scope.taskListsList = null
                allTodoLists = dsDataService.findDataSet $scope, type: TaskList, mode: 'original', project: edit.project
                allTodoLists.watchStatus $scope, (source, status, prevStatus, unwatch) ->
                  # TODO: Select current task list
                  $scope._unwatch4 = ->
                    unwatch()
                    allTodoLists.release $scope
                    if $scope.taskLists
                      taskList.release $scope for taskList in $scope.taskLists
                      $scope.taskLists = null
                    return
                  return unless status == 'ready'
                  unwatch(); $scope._unwatch4 = null
                  project.addRef $scope for project in ($scope.taskListsList = (todoList for todoListKey, todoList of allTodoLists.items).sort (l, r) -> l.get('position') - r.get('position'))
                  allTodoLists.release $scope
              else
                if $scope.taskLists
                  taskList.release $scope for taskList in $scope.taskLists
                  $scope.taskLists = null
              return
          allProjects.release $scope
          return

        $scope.task = task = # fake task, to do not have a deal with rewriting task split logic
          $new: true
          $u: Task$u
          get: (propName) ->
            switch propName
              when 'split', 'duedate', 'responsible', 'tags' then null
              else throw new Error "Unexpected prop: #{propName}"

      else
        edit.project = task.get('project')
        edit.taskList = task.get('taskList')
        edit.title = task.get('title')
        edit.duedate = duedate = task.get('duedate')
        edit.estimate = task.get('estimate')
        edit.responsible = task.get('responsible')
        edit.description = task.get('description')
        edit.tags = task.get('tags')

      $scope.$watch (-> edit.tags), (val) ->
        $scope.orderedTags =
          if val
            (tag for tagName, tag of val.map).sort (l, r) -> if (d = l.get('priority') - r.get('priority')) != 0 then d else l.get('name').localeCompare(r.get('name'))
          else []
        return

      (updateTagsToSelect = ->
        allTags = dsDataService.findDataSet $scope, type: Tag, mode: 'original'
        allTags.watchStatus $scope, (source, status, prevStatus, unwatch) ->
          $scope._unwatch2 = unwatch
          return unless status == 'ready'
          unwatch(); $scope._unwatch2 = null
          $scope.tagsToSelect = (tag for tagName, tag of allTags.items when not edit.tags?.get(tagName)).sort (l, r) -> if (d = l.get('priority') - r.get('priority')) != 0 then d else l.get('name').localeCompare(r.get('name'))
          allTags.release $scope
          return
        return)()

      edit.tagsSelected = null

      $scope.$watch (-> edit.tagsSelected), -> # add tag
        return unless edit.tagsSelected
        tagsValue = if (oldTags = edit.tags) then edit.tags.clone($scope) else new DSTags($scope)
        tagsValue.set edit.tagsSelected.name, edit.tagsSelected
        edit.tags = tagsValue
        oldTags.release $scope if oldTags && task.get('tags') != oldTags
        edit.tagsSelected = null
        updateTagsToSelect()
        return

      $scope.tagsRemove = (tag) ->
        if Object.keys((oldTags = edit.tags).map).length > 1
          tagsValue = oldTags.clone($scope)
          tagsValue.set tag.name, false
          edit.tags = tagsValue
        else
          edit.tags = null
        oldTags.release $scope if oldTags && task.get('tags') != oldTags
        updateTagsToSelect()
        return

      edit.splitDiff = null
      edit.firstWeek = thisWeek = moment().startOf('week')
      edit.splitDuedate = if duedate != null then duedate else moment().startOf('day')
      if edit.isSplit = (edit.split = if (split = task.get('split')) != null then split.clone() else null) != null && edit.duedate != null && edit.estimate != null
        first = moment(split.firstDate(duedate)).startOf('week')
        last = moment(split.lastDate(duedate)).startOf('week')
        if (weeks = moment.duration(last.diff(first)).asWeeks()) < splitViewWeeksCount # can fit
          if first.isBefore(thisWeek) then edit.firstWeek = first # start prior current week
          else if !(moment.duration(last.diff(thisWeek)).asWeeks() <= splitViewWeeksCount) then edit.firstWeek = last.subtract(splitViewWeeksCount - 1, 'week') # cannot start from current week, to show last split
        else
          edit.firstWeek = first # cannot fit, so let's show from first split week
        makeSplitView()
      else
        edit.splitView = null

      if !($scope.viewonly = !task.$u || _.isEmpty(task.$u))
        $scope.changes = false
        $scope.$watch (->
          res = [ # watch all possible changes, except isSplit that has special logic
            if (project = edit.project) == null then null else project.$ds_key
            if (taskList = edit.taskList) == null then null else taskList.$ds_key
            edit.title
            edit.description
            if (duedate = edit.duedate) == null then null else duedate.valueOf()
            if (estimate = edit.estimate) == null then null else estimate.valueOf()
            if (responsible = edit.responsible) == null then null else responsible.$ds_key
            if (tags = edit.tags) == null then null else tags.valueOf()]
          res = res.concat val if (split = edit.split) != null && (val = split.valueOf()).length > 0 # append split if there is some. intentionally not taking edit.isSplit
          return res),
          ((val, oldVal) ->
            $scope.changes = (val != oldVal)
            edit.isSplit = false if val[4] == null || val[5] == null
            return), true
        $scope.$watch (-> edit.isSplit), ((isSplit, oldIsSplit) -> # watch isSplit
          if isSplit
            edit.split = new TaskSplit() if edit.split == null
            makeSplitView() if edit.splitView == null
          else
            releaseSplitView() if edit.splitView != null
          $scope.changes = true if isSplit != oldIsSplit && edit.split?.valueOf().length > 0 # it's non empty split
          return)
        $scope.$watch (-> edit.duedate?.valueOf()),
          ((duedateValue, oldDuedateValue) -> # shift task.split on duedate change, if suitable
            return if duedateValue == oldDuedateValue || !typeof duedateValue == 'number'
            $scope.changes = true
            if edit.split != null && duedateValue != null && oldDuedateValue != null
              edit.splitDuedate.add (duedateValue - oldDuedateValue)
            return)
        $scope.$watch (-> [edit.estimate?.valueOf(), edit.isSplit, edit.split]), (([estimateVal, isSplit, split]) -> # calculate difference between estimate and task.split
          if typeof estimateVal == 'number' && isSplit && split != null
            newVal = (newDiff = moment.duration(split.total).subtract(estimateVal)).valueOf()
            edit.splitDiff = if newVal != 0 && ((splitDiff = edit.splitDiff) == null || splitDiff.valueOf() != newVal) then newDiff else null
          else edit.splitDiff = null
          return), true
      $scope.splitPrevWeek = (-> # click on left arrow on task.split
        edit.firstWeek = monday = moment(edit.firstWeek).subtract(1, 'week')
        edit.splitView.unshift newTaskSplitWeekView monday
        edit.splitView.pop().release $scope
        return)
      $scope.splitNextWeek = (-> # click on right arrow on task.split
        monday = moment(edit.firstWeek.add(1, 'week')).add(splitViewWeeksCount - 1, 'week')
        edit.splitView.push newTaskSplitWeekView monday
        edit.splitView.shift().release $scope
        return)

      $scope.close = close = (->
        $rootScope.modal = {type: null}
        return)

      $scope.save = (($event, plan) ->
        if assert
          error.invalidArg 'plan' unless typeof plan == 'undefined' || typeof plan == 'boolean'

        # Fix duedate, estimate if split
        if edit.isSplit && edit.split.list.length > 0
          edit.duedate = edit.splitDuedate

          # Rule: If total split not equal to estimate, then split gets fixed
          splitTotal = split.total
          if (estimate = edit.estimate) == null
            # Rule: if estimate is not defined it becomes a sum of splitted time
            edit.estimate = splitTotal
          else if (diff = (estimate.valueOf() - splitTotal.valueOf())) != 0
            # Rule: Original estimate wons split
            split.fixEstimate diff

        # Actual save...
        update = {}
        if task.$new
          update.project = edit.project
          update.taskList = edit.taskList
        update.title = edit.title
        update.duedate = edit.duedate
        update.estimate = edit.estimate
        update.responsible = edit.responsible
        update.split = if edit.isSplit && edit.split.valueOf().length > 0 then edit.split else null
        update.tags = edit.tags
        update.description = edit.description
        update.plan = plan if typeof plan == 'boolean'

        addCommentAndSave task, $event.shiftKey, update
        .then ((saved) ->
          close() if saved
          return)
        return)

      $scope.showTimeLeft = ((dayModel) ->
        return '' if (timeLeft = dayModel.get('timeLeft')) == null
        plan = dayModel.get('plan')
        initPlan = dayModel.get('initPlan')
        diff = moment.duration timeLeft
        # TODO: Use edit.responsible
        diff.add initPlan if initPlan != null && $scope.task.get('responsible') == edit.responsible
        diff.subtract val if (val = plan.val) != null
        res = if (val = diff.valueOf()) < 0 then (diff = moment.duration(-val); '- ') else ''
        hours = Math.floor diff.asHours()
        minutes = diff.minutes()
        res += "#{hours}h #{if minutes < 10 then '0' + minutes else minutes}m"
        return res)
      $scope.autoSplitInProgress = false
      $scope.autoSplit = (->
        if assert
          throw new Error "Invalid duedate: #{edit.duedate?.format()}" if !(edit.duedate != null && time.today <= edit.duedate)
          throw new Error "Invalid value 'edit.responsible': #{edit.responsible}" if !(edit.responsible != null)
          throw new Error "Invalid value 'edit.estimate': #{edit.estimate?.valueOf()}" if !(edit.estimate != null && edit.estimate > 0)

        $scope.autoSplitInProgress = true

        reponsibleKey = edit.responsible.$ds_key
        d = moment(duedate = edit.duedate)
        e = moment.duration(edit.estimate)
        (split = edit.split).clear()
        edit.splitDuedate = moment(d)
        initDuedate = $scope.task.get('duedate')
        initSplit = if initDuedate != null && edit.responsible == $scope.task.get('responsible') then $scope.task.get('split') else null

        splitWithinWeek = (->
          personDayStatSet = dsDataService.findDataSet $scope,
            type: PersonDayStat
            mode: 'edited'
            startDate: weekStart = moment(d).startOf 'week'
            endDate: moment(d).endOf 'week'
          $scope._unwatch = personDayStatSet.watchStatus $scope, ((set, status, prevStatus, unwatch) ->
            return if status != 'ready'
            dayStats = set.items[reponsibleKey].get('dayStats')
            while e > 0 && time.today <= d && weekStart <= d
              timeLeft = (dayStat = dayStats[moment.duration(d.diff(weekStart)).asDays()]).timeLeft
              if initSplit != null
                (timeLeft = moment.duration(timeLeft)).add initPlan if (initPlan = initSplit.get initDuedate, d) != null
              if timeLeft > 0
                split.set duedate, d, (dayTime = moment.duration(Math.min(timeLeft.valueOf(), e.valueOf())))
                e.subtract dayTime
              d.subtract 1, 'day'
            unwatch() # Note: personDayStatSet cannot be used after this operation, since it's released
            delete $scope._unwatch
            if e > 0 && time.today <= d
              # Note: At the moment we hardcode that sat&sun are weekends, and we do not split tasks on them
              d.subtract 2, 'days'
              splitWithinWeek() # split on previouse week
            else $scope.autoSplitInProgress = false
            return)
          personDayStatSet.release $scope
          return)

        splitWithinWeek()

        return)
    ))]
