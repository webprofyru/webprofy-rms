module.exports = (ngModule = angular.module 'ui/tasks/TaskSplitWeekView', [
  require('../../../dscommon/DSView')
]).name

assert = require('../../../dscommon/util').assert

DSObject = require('../../../dscommon/DSObject')

TaskSplit = require('../../models/types/TaskSplit')
Task = require('../../models/Task')
Person = require('../../models/Person')
PersonDayStat = require('../../models/PersonDayStat')

time = require '../time'

ngModule.factory 'TaskSplitWeekView', ['DSView', '$log', ((DSView, $log) ->

  class DayModel extends DSObject
    @begin 'DayModel'

    @ds_dstr.push (->
      @__unwatch1?()
      @__unwatch2?()
      return)

    @propDuration 'timeLeft'
    @propDuration 'timeLeftShow'
    @propObj 'plan'
    @propDuration 'initPlan'
    @propBool 'select'
    @end()

  return class TaskSplitWeekView extends DSView
    @begin 'TaskSplitWeekView'

    TaskSplit.addPropType @

    @propData 'personDayStat', PersonDayStat, {mode: 'edited'}

    @propList 'days', DayModel

    @propMoment 'monday'
    @propDoc 'responsible', Person
    @propMoment 'today'
    @propMoment 'duedate'
    @propTaskRelativeSplit 'split'

    constructor: (($scope, key, getDuedate, split, monday) ->
      if assert
        error.invalidArg 'getDuedate' if !typeof getDuedate == 'function'
        error.invalidArg 'split' if !split instanceof TaskSplit
        error.invalidArg 'monday' if !moment.isMoment(monday)
        error.invalidArg 'getPerson' if !typeof getPerson == 'function'
        error.invalidArg 'getDuedate' if !typeof getDuedate == 'function'
      DSView.call @, $scope, key
      @set 'split', split
      @set 'monday', monday
      $scope.$watch 'edit.responsible', ((responsible) =>
        @set 'responsible', responsible
        @__dirty++ # make render work on any person change
        return)
      @dataUpdate {startDate: monday, endDate: moment(monday).endOf('week'), mode: $scope.mode}

      initSplit = $scope.edit.split
      splitDuedate = $scope.edit.splitDuedate
      date = moment(monday)
      @get('daysList').merge @, days = (for d in [0...7]
        dayModel = new DayModel @, "#{d}"
        do(dayModel, date) =>
          dayModel.set 'initPlan', initPlan = if initSplit == null then null else initSplit.get splitDuedate, date
          dayModel.set 'plan', split.day(getDuedate, date) # link view model to split days
          if date.valueOf() == time.today then dayModel.set 'select', true
          else if date > time.today
            dayModel.__unwatch1 = $scope.$watch 'edit.duedate', ((duedate) ->
              dayModel.set 'select', duedate != null && date <= duedate
              return)
          dayModel.__unwatch2 = $scope.$watch (-> [$scope.$eval('edit.responsible')?.$ds_key, dayModel.get('plan')?.val, dayModel.get('timeLeft')?.valueOf()]),
            (([responsibleKey, plan, timeLeft]) ->
              if typeof timeLeft != 'number' then dayModel.set 'timeLeftShow', null
              else
                diff = moment.duration timeLeft
                diff.add initPlan if initPlan != null && (responsible = $scope.task.get('responsible')) != null && responsible.$ds_key == responsibleKey
                diff.subtract plan if moment.isDuration(plan)
                dayModel.set 'timeLeftShow', diff
              return), true
        (date = moment(date)).add(1, 'day')
        dayModel)

      return)

    render: (->
      if (responsible = @get 'responsible') != null && ((status = @data.get('personDayStatStatus')) == 'ready' || status == 'update')
        if assert
          throw new Error 'Missing person' if !@data.get('personDayStat').hasOwnProperty(responsible.$ds_key)
        dayStats = @data.get('personDayStat')[responsible.$ds_key].get('dayStats')
        d.set 'timeLeft', dayStats[i].get('timeLeft') for d, i in @get('days')
      else d.set 'timeLeft', null for d in @get('days')
      return)

    @end())]
