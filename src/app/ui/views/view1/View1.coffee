module.exports = (ngModule = angular.module 'ui/views/view1/View1', [
  require '../../../config'
  require '../../../data/dsChanges'
  require '../../../data/dsDataService'
  require '../../../../dscommon/DSView'
  require '../../tasks/addCommentAndSave'
  require '../../../data/teamwork/TWTasks'
]).name

assert = require('../../../../dscommon/util').assert

DSDigest = require '../../../../dscommon/DSDigest'

# Global models
Task = require('../../../models/Task')
Tag = require('../../../models/Tag')
Person = require('../../../models/Person')
PersonDayStat = require('../../../models/PersonDayStat')
PersonTimeTracking = require('../../../models/PersonTimeTracking')

# View specific models
Day = require('./models/Day')
Row = require('./models/Row')
TaskView = require('./models/TaskView')

serviceOwner = require('../../../../dscommon/util').serviceOwner

ngModule.controller 'View1', [
  '$scope', 'View1', '$rootScope',
  ($scope, View1, $rootScope) ->
    $rootScope.view1 = $scope.view = new View1 $scope, 'view1'
    $scope.$on '$destroy', (-> delete $rootScope.view1; return)
    $scope.expandedHeight = (row)->
        return '' if !row.expand
        return "height:100px" if _.isEmpty row.tasks
        return "height:#{65 * _.maxBy(row.tasks, 'y').y + 98}px"
    return] # ($scope, View1, $rootScope) ->

ngModule.factory 'View1', ['DSView', 'config', '$rootScope', '$log', 'TWTasks', ((DSView, config, $rootScope, $log, TWTasks) ->

  return class View1 extends DSView
    @begin 'View1'

    @propData 'people', Person, {watch: ['roles', 'companyId']}
    @propData 'tasks', Task, {filter: 'assigned', watch: ['responsible', 'duedate', 'split', 'estimate', 'priority']}
    @propData 'personDayStat', PersonDayStat, {}
    @propData 'personTimeTracking', PersonTimeTracking, {watch: []}

    @propMoment 'startDate'
    @propList 'days', Day

    @propPool 'poolRows', Row
    @propList 'rows', Row

    @propNum 'renderVer', 0

    @propObj 'hiddenPeople', init: {}
    @propNum 'hiddenPeopleCount', init: 0

    @ds_dstr.push (->
      @__unwatchA()
      @__unwatchB()
      @__unwatchC()
      return)

    constructor: (($scope, key) ->
      DSView.call @, $scope, key

      @scope = $scope
      @set 'startDate', moment().startOf('week')

      $scope.filterLoad = [
        $scope.selectedLoad = {id: 0, name: 'All'}
        {id: -1, name: 'Underload'}
        {id: 1, name: 'Overload'}]

      if (selectedLoad = config.get('selectedLoad'))
        for i in $scope.filterLoad when i.id == selectedLoad
          $scope.selectedLoad = i

      if config.hasRoles # it's webProfy

        $scope.filterCompanies = [
          {id: -1, name: 'All'}
          $scope.selectedCompany = {id: 23872, name: 'WebProfy'}
          {id: 50486, name: 'Freelancers'}]

        selectedCompany = config.get('selectedCompany')
        for i in $scope.filterCompanies when i.id == selectedCompany
          $scope.selectedCompany = i
          break

      @__unwatchA = $scope.$watch((=> [
          @get('startDate')?.valueOf(),
          $scope.mode,
          $scope.dataService.showTimeSpent,
          $scope.selectedManager?.$ds_key]),
        (([startDateVal, mode, showTimeSpent, selectedManager]) =>
          @dataUpdate
            startDate: moment(startDateVal)
            endDate: moment(startDateVal).add(6, 'days')
            mode: mode
            showTimeSpent: showTimeSpent
            manager: if selectedManager then selectedManager else null
          return), true)

      @__unwatchB = $scope.$watch (-> [
          $scope.selectedRole, $scope.selectedCompany, $scope.selectedManager, $scope.selectedLoad]),
        (([selectedRole, selectedCompany, selectedManager, selectedLoad]) =>
          if $rootScope.peopleRoles
            config.set 'selectedRole', if selectedRole then selectedRole.role else null
            $scope.selectedRole = null unless selectedRole?.role
          if $rootScope.filterManagers
            config.set 'selectedManager', if selectedManager then selectedManager.$ds_key else null
            $scope.selectedManager = null unless selectedManager?.$ds_key
          config.set 'selectedCompany', if selectedCompany then selectedCompany.id else null
          config.set 'selectedLoad', if selectedLoad then selectedLoad.id else 0
          @__dirty++), true

      @__unwatchC = $scope.$watch (=> [config.get('currentUserId'), @get('data').get('peopleStatus')]), (([currentUserId, peopleStatus]) =>
        unless currentUserId != null && (peopleStatus == 'ready' || peopleStatus == 'update')
          config.set 'currentUser', null
          return
        config.set 'currentUser', @get('data').get('people')[currentUserId]
        return), true

      return)

    periodChange: ((num) ->
      @set 'startDate', @startDate.add(num, 'week')
      return)

    hideRow: ((row) ->
      @get('hiddenPeople')[row.$ds_key] = true
      @hiddenPeopleCount++
      @__dirty++
      return)

    unhideAll: (->
      @set 'hiddenPeople', {}
      @hiddenPeopleCount = 0
      @__dirty++
      return)

    render: (->
      if !((peopleStatus = @get('data').get('peopleStatus')) == 'ready' || peopleStatus == 'update')
        @get('rowsList').merge @, []
        return

      startDate = @get 'startDate'

      days = @get('daysList').merge @, _.map [0..6], ((dayIndex, index) =>
          date = moment(startDate).add(dayIndex, 'days')
          day = new Day @, date.format()
          day.set 'date', date
          day.set 'index', index
          day.set 'x', dayIndex
          return day)

      filter = (-> true)
      hiddenPeople = @get('hiddenPeople')
      for k of hiddenPeople # is there at least one person within the map
        filter = ((person) -> !hiddenPeople.hasOwnProperty(person.$ds_key))
        break

      if config.get('hasRoles') # it's WebProfy extended case

        if @scope.selectedCompany?.id != -1
          companyId = @scope.selectedCompany.id
          f0 = filter
          filter = ((person) -> f0(person) && person.get('companyId') == companyId)
        else
          f0 = filter

        if @scope.selectedRole?.role
          selectedRole = @scope.selectedRole
          f1 = filter
          if selectedRole.hasOwnProperty('roles')
            rolesMap = {}
            for r in selectedRole.roles.split(',')
              rolesMap[r.trim()] = true
            filter = ((person) -> f1(person) && person.get('roles')?.any(rolesMap))
          else if selectedRole.hasOwnProperty('special')
            switch selectedRole.special
              when 'notSupervisors'
                filter = ((person) -> f1(person) && ((roles = person.get('roles')) == null || !roles.get('Manager'))) # Hack: It's hardcoded role name
              else
                console.error "Unexpected role.special value: #{role.special}", selectedRole
          else
            role = selectedRole.role
            filter = ((person) -> f1(person) && person.get('roles')?.get(role))

        if @scope.selectedLoad?.id != 0
          return if (personDayStatStatus = @get('data').get('personDayStatStatus')) != 'ready' && personDayStatStatus != 'update'
          personDayStat = @get('data').get('personDayStat')
          loadFilter = if @scope.selectedLoad.id == 1
            ((person) ->
              (return true if dayStat.get('timeLeft') < 0) for dayStat in personDayStat[person.$ds_key].get('dayStats')
              return false)
          else # underload
            ((person) ->
              for dayStat in personDayStat[person.$ds_key].get('dayStats')
                return true if dayStat.get('timeLeft').valueOf() / dayStat.get('contract').valueOf() > 0.2 # loaded less then 80%
              return false)
          f2 = filter
          filter = ((person) -> f2(person) && loadFilter(person))

      selectedPeople = _.filter @data.get('people'), filter

      selectedPeople.sort ((left, right) -> if (leftLC = left.name.toLowerCase()) < (rightLC = right.name.toLowerCase()) then -1 else if leftLC > rightLC then 1 else 0)

      poolRows = @get 'poolRows'
      rows = @get('rowsList').merge @, _.map selectedPeople, ((person) =>
          row = poolRows.find @, person.$ds_key
          row.set 'person', person
          return row)

      # Temp array for calculate total work time by days
      daysTemp =  _.map [0..6], (-> moment.duration(0))
      timeSpentTemp = _.map [0..6], (-> moment.duration(0))

      unless ((tasksStatus = @get('data').get('tasksStatus')) == 'ready' || tasksStatus == 'update') &&
           ((personDayStatStatus = @get('data').get('personDayStatStatus')) == 'ready' || personDayStatStatus == 'update')
        _.forEach rows, ((row) => # clear all
          row.get('tasksList').merge @, []
          row.set 'personDayStat', null
          return)
      else # render
        tasksByPerson = _.groupBy @data.tasks, ((task) -> task.get('responsible').$ds_key)
        timeByPerson = null
        if (personTimeTrackingStatus = @data.personTimeTrackingStatus) == 'ready' || personTimeTrackingStatus == 'update'
          timeSpentTemp = _.map [0..6], (-> moment.duration(0))
          timeByPerson = _.groupBy (personTimeTracking = @data.personTimeTracking), ((task) -> task.get('personId'))
        _.forEach rows, ((row) =>

          # fill totals
          row.set 'personDayStat', personDayStat = @data.get('personDayStat')[row.$ds_key]
          daysTemp[i].add ds.get('tasksTotal') for ds, i in dayStats = personDayStat.get('dayStats')

          # create collection of taskView
          tasksPool = row.get 'tasksPool'
          takenTime = {}
          taskViews = _.map tasksByPerson[row.$ds_key], ((task) =>
            taskView = tasksPool.find @, task.$ds_key
            taskView.set 'task', task
            if timeByPerson # link time to active tasks # mark as taken time for non-completed split tasks. time will be used in getTime method below
              if (split = task.get('split'))
                duedate = task.get('duedate')
                start = if (firstDate = split.firstDate(duedate)) <= startDate then 0 else moment.duration(firstDate.diff(startDate)).asDays()
                for day in @get('days')[start..6]
                  if (time = personTimeTracking["#{row.$ds_key}-#{task.$ds_key}-#{day.get('date').valueOf()}"])
                    takenTime[time.$ds_key] = true
              else if (time = personTimeTracking["#{row.$ds_key}-#{task.$ds_key}-#{task.get('duedate').valueOf()}"]) # set time for non-completed non-split tasks
                  takenTime[time.$ds_key] = true
                  taskView.set 'time', time
              else # no time for this task
                taskView.set 'time', null
            return taskView)
          if timeByPerson && (timeByThisPerson = timeByPerson[row.$ds_key])
            # add taskViews for the PersonTimeTracking objectы left after linking to a tasks
            for time in timeByThisPerson when !takenTime[time.$ds_key]
              taskViews.push (taskView = tasksPool.find @, time.$ds_key)
              taskView.set 'time', time
            # update timeSpent in dayStats
            timeTrackingByDates = _.groupBy timeByThisPerson, ((personTTracking) -> personTTracking.get('date').valueOf())
            for dayStat, i in personDayStat.get('dayStats')
              if dayTimeTrackingByDates = timeTrackingByDates[dayStat.get('day').valueOf()]
                timeSpentTemp[i].add(dayStat.set('timeSpent', (_.reduce dayTimeTrackingByDates, ((res, val) -> res.add(val.get('timeMin'), 'm')), moment.duration())))
              else dayStat.set 'timeSpent', null
          else dayStat.set 'timeSpent', null for dayStat in personDayStat.get('dayStats')

          row.get('tasksList').merge @, taskViews

          getTime = null
          if timeByPerson
            getTime = ((taskView, date) -> # this method is used to put time into split-tasks
              return if (time = personTimeTracking["#{row.$ds_key}-#{taskView.get('task').$ds_key}-#{date.valueOf()}"]) then time else null)

          View1.layoutTaskView startDate, taskViews, getTime

          return)

      # fill total work time by days - top of the whole view1 matrix
      _.forEach days, ((day, index) ->
        day.set 'workTime', daysTemp[index]
        day.set 'timeSpent', if (timeSpentTemp[index].valueOf() == 0) then null else timeSpentTemp[index]
        return)

      @set 'renderVer', (@get('renderVer') + 1)

      return)

    # 1. open tasks comes first
    # 2. closed tasks, if any, comes after
    @taskViewsSortRule = taskViewsSortRule = ((leftView, rightView) ->
      leftTask = leftView.get('task')
      rightTask = rightView.get('task')

      return rightView.get('time').get('taskId') - leftView.get('time').get('taskId') if leftTask == null and rightTask == null
      return 1 if leftTask == null
      return -1 if rightTask == null

      return TWTasks.tasksSortRule leftTask, rightTask)

    positionTaskView = ((pos, taskView, taskStartDate, day, getTime) ->
      taskView.set 'x', day
      dayPos = pos[day]
      if day == 0 then y = dayPos.length
      else
        break for v, y in dayPos when typeof v == 'undefined'
      taskView.set 'y', y
      if (task = taskView.get('task')) == null || (split = task.get('split')) == null
        taskView.set 'split', null
        taskView.set 'len', 1 # one day task - no split
        dayPos.length++ if y == dayPos.length
        dayPos[y] = true
      else # note: task with split also could be one day length
        len = taskView.set 'len', Math.min(moment.duration(moment(split.lastDate(task.get('duedate'))).diff(taskStartDate)).asDays() + 1, 7 - day)
        viewSplit = taskView.set 'split', []
        for s in [0...len] # mark next days
          date = if s == 0 then taskStartDate else moment(taskStartDate).add(s, 'day')
          time = if getTime then getTime(taskView, date) else null
          if (plan = split.get(task.duedate, date)) != null || time != null
            viewSplit.push {x: s, plan, time}
          dpos.length = y if (dpos = pos[day + s]).length <= y
          dpos[y] = true
      return y)

    # It's common functionality used in View1 and View2.  Parameter getTime is only used in View1
    @layoutTaskView = ((startDate, taskViews, getTime) ->
      maxY = 0
      # fill taskViews with respect to split
      if !_.some taskViews, ((taskView) -> taskView.get('task')?.get('split')) # simple case, then all taskViews are one day long
        tasksByDay = _.groupBy taskViews, ((taskView) ->
          (if (time = taskView.get('time')) then time.get('date') else taskView.get('task').get('duedate')).valueOf())
        _.forEach tasksByDay, ((taskViews, date) ->
          taskViews.sort taskViewsSortRule
          x = moment.duration((if (time = taskViews[0].get('time')) then time.get('date') else taskViews[0].get('task').get('duedate')).diff(startDate)).asDays()
          _.forEach taskViews, ((taskView, i) ->
            taskView.set 'x', x
            maxY = Math.max maxY, taskView.set 'y', i
            taskView.set 'len', 1
            taskView.set 'split', null
            return)
          return)
      else # there are long taskViews, so we should place them with respect to split.firstDate and make sure that taskViews are not get overlapped
        tasksByDay = _.groupBy taskViews, ((taskView) ->
          if (task = taskView.get('task'))
            duedate = task.get('duedate')
            return (if (split = task.get('split')) != null then split.firstDate(duedate) else duedate).valueOf()
          return taskView.get('time').get('date').valueOf())
        pos = ([] for i in [0..6]) # matrix there we will mark that positions is busy
        groupDates = (parseInt(t) for t of tasksByDay).sort()
        for d in groupDates # process taskViews started before the startDate
          (tasksForTheDay = tasksByDay[d]).sort taskViewsSortRule
          day = moment.duration((taskStartDate = moment(d)).diff(startDate)).asDays()
          if day < 0
            day = 0
            taskStartDate = startDate
          _.forEach tasksForTheDay, ((taskView) -> maxY = Math.max maxY, positionTaskView(pos, taskView, taskStartDate, day, getTime); return)
      return maxY + 1)

    @end())]

ngModule.factory 'getDropTasksGroup', [
  'dsDataService', '$rootScope',
  (dsDataService, $rootScope) ->
    allTasks = serviceOwner.add dsDataService.findDataSet serviceOwner, {type: Task, mode: 'edited', filter: 'all'}
    -> # (dsDataService, $rootScope) ->
      duedate = $rootScope.modal.task.get('duedate').valueOf()
      responsible = $rootScope.modal.task.get('responsible')
      project = $rootScope.modal.task.get('project')
      res = (t for k, t of allTasks.items when !t.plan && !t.split && t.get('responsible') == responsible && t.get('duedate')?.valueOf() == duedate && t.get('project') == project)
      if res.length == 0 then [$rootScope.modal.task] else res] # res.length == 0 could be when d'n'd task has plan == true

ngModule.directive 'rmsView1DropTask', [
  'View1', '$rootScope', 'dsChanges', 'addCommentAndSave', 'getDropTasksGroup',
  (View1, $rootScope, dsChanges, addCommentAndSave, getDropTasksGroup) -> # () ->
    restrict: 'A'
    scope: true
    link: ($scope, element, attrs) ->

      el = element[0]

      el.addEventListener 'dragover', (ev) ->
        ev.preventDefault()
        true # (ev) ->

      el.addEventListener 'drop', (ev) ->

        if ev.dataTransfer.getData('task')
          day = _.findIndex $('.drop-zone', element), (value) ->
            $v = $(value)
            $v.offset().left + $v.width() >= ev.clientX # (value) ->

          unless ev.ctrlKey && !(modal = $rootScope.modal).task.split && modal.task.duedate != null
            tasks = [$rootScope.modal.task]
          else # group movement, if task has no split and 'ctrl' key is pressed while operation
            tasks = getDropTasksGroup()

          if day < 0
            addCommentAndSave tasks, ev.shiftKey, # You have to keep shift, if you need to make a comment
              responsible: $scope.row.get('person')
              plan: false
          else
            addCommentAndSave tasks, ev.shiftKey, # You have to keep shift, if you need to make a comment
              responsible: $scope.row.get('person')
              duedate: $scope.view.get('days')[day].get('date')
              plan: false

        $rootScope.$digest()
        ev.stopPropagation()
        false] # (ev) ->

ngModule.directive 'rmsView1MouseOverWeekChange', [
  'View1', '$rootScope', 'dsChanges', 'addCommentAndSave',
  (View1, $rootScope, dsChanges, addCommentAndSave) -> # () ->
    restrict: 'A'
    link: ($scope, element, attrs) ->
      direction = $scope.$eval attrs.rmsView1MouseOverWeekChange
      lastTimeStamp = 0

      el = element[0]

      el.addEventListener 'dragover', (ev) ->

        if ev.timeStamp > lastTimeStamp
          lastTimeStamp = ev.timeStamp + 3000
          $rootScope.view1.periodChange direction
          $rootScope.$digest()

        ev.preventDefault()
        true # (ev) ->

      return] # link:

