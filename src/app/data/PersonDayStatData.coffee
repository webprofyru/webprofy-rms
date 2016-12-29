module.exports = (ngModule = angular.module 'data/PersonDayStatData', [
]).name

assert = require('../../dscommon/util').assert
error = require('../../dscommon/util').error

DSDocument = require '../../dscommon/DSDocument'
DSDataServiceBase = require '../../dscommon/DSDataServiceBase'
DSData = require '../../dscommon/DSData'
DSDigest = require '../../dscommon/DSDigest'
DSSet = require '../../dscommon/DSSet'

Person = require '../models/Person'
Task = require '../models/Task'
PersonDayStat = require '../models/PersonDayStat'

ngModule.factory 'PersonDayStatData', [(->

  return class PersonDayStatData extends DSData

    @begin 'PersonDayStatData'

    @addPool()

    @propDoc 'tasks', DSSet
    @propDoc 'people', DSSet

    @propSet 'personDayStats', PersonDayStat

    @ds_dstr.push (->
      @_unwatchA?()
      @_unwatchB?()
      @_unwatch1?()
      @_unwatch2?()
      return)

    clear: (->
      DSData::clear.call @
      @_unwatch1?(); delete @_unwatch1
      @_unwatch2?(); delete @_unwatch2
      return)

    init: ((dsDataService) ->
      if assert
        error.invalidArg 'dsDataService' if !(dsDataService instanceof DSDataServiceBase)

      (tasks = @set 'tasks', dsDataService.findDataSet @, (_.assign {}, @params, {type: Task, filter: 'assigned'})).release @
      tasksItems = tasks.items
      (people = @set 'people', dsDataService.findDataSet @, {type: Person, mode: @params.mode}).release @
      peopleItems = people.items
      personDayStats = @get('personDayStats')

      load = (=>
        return if !@_startLoad()
        tasksByPerson = _.groupBy tasksItems, ((task) -> task.get('responsible').$ds_key)
        daysCount = moment.duration((endDate = @params.endDate).diff(startDate = @params.startDate)).asDays()
        d = startDate
        days = (((d = moment(r = d)).add(1, 'day'); r) for i in [0..daysCount])
        calcOnePersonStat = ((personDayStat) =>
          tasksCounts = (0 for d in days)
          tasksTotal = (moment.duration(0) for d in days)
          dayStats = personDayStat.get('dayStats')
          if tasksByPerson.hasOwnProperty(personKey = (person = personDayStat.get('person')).$ds_key)
            personTasks = tasksByPerson[personKey]
            for task in personTasks
              if (duedate = task.duedate) != null # Zork: Duedate might become null once we delete due date in task edit dialog
                if (split = task.get('split')) != null
                  for d, i in (splitVal = split.list) by 2
                    n = moment(duedate).add(d).diff(startDate) // (24 * 60 * 60 * 1000)
                    if 0 <= n < dayStats.length
                      tasksTotal[n].add(splitVal[i + 1])
                      tasksCounts[n]++
                else
                  n = (duedate.valueOf() - startDate.valueOf()) // (24 * 60 * 60 * 1000)
                  if 0 <= n < dayStats.length
                    tasksTotal[n].add estimate if (estimate = task.get('estimate')) != null
                    tasksCounts[n]++
          contractTime = person.get('contractTime')
          totalPeriodTime = moment.duration(0)
          for s, i in dayStats
            s.set 'tasksCount', tasksCounts[i]
            s.set 'contract', contractTime
            s.set 'tasksTotal', ttotal = tasksTotal[i]
            s.set 'timeLeft', moment.duration(contractTime).subtract ttotal
            totalPeriodTime.add ttotal
          personDayStat.set 'totalPeriodTime', totalPeriodTime
          return)

        statMap = {}
        for personKey, person of peopleItems
          calcOnePersonStat (statMap[personKey] = new PersonDayStat @, person.$ds_key, person, days)
        @get('personDayStatsSet').merge @, statMap

        digestRecalc = ((personKey) ->
          return if !personDayStats.hasOwnProperty(personKey)
          calcOnePersonStat personDayStats[personKey]
          return)

        personRecalc = ((person) =>
          if assert
            error.invalidArg 'person' if !(person instanceof Person)
          DSDigest.render @$ds_key, person.$ds_key, digestRecalc
          return)

        @_unwatch1 = tasks.watch @,
          change: change = ((task, propName, val, oldVal) ->
            if propName == 'estimate' || propName == 'split' || propName == 'duedate'
              personRecalc person if (person = task.get('responsible')) != null && task.get('duedate') != null
            else if propName == 'responsible'
              if oldVal != null && tasksByPerson.hasOwnProperty(personKey = oldVal.$ds_key)
                personRecalc oldVal if (_.remove tasksByPerson[personKey], task).length > 0
              if val != null
                tasks = if tasksByPerson.hasOwnProperty(personKey = val.$ds_key) then tasksByPerson[personKey] else tasksByPerson[personKey] = []
                if !_.find tasks, task
                  tasks.push task
                  personRecalc val
            return)
          add: ((task) -> change task, 'responsible', task.get('responsible'), null; return)
          remove: ((task) ->
            if (person = task.get('responsible')) != null && tasksByPerson.hasOwnProperty(personKey = person.$ds_key)
              _.remove tasksByPerson[personKey], task
              personRecalc person
            return)

        @_unwatch2 = people.watch @,
          add: ((person) =>
            s = new PersonDayStat @, (key = person.$ds_key), person, days
            s.get('dayStatsList').merge @, (((r = new PersonDayStat.DayStat(@, "personKey_#{i}")).set('day', d); r) for d, i in days)
            @get('personDayStatsSet').add @, s
            personRecalc person
            return)
          remove: ((person) => @get('personDayStatsSet').remove @get('personDayStats')[person.$ds_key]; return)
          change: ((person, propName, val, oldVal) -> personRecalc person if propName == 'contractTime'; return)

        @_endLoad true
        return)

      sets = [tasks, people]
      updateStatus = ((source, status) =>
        if !((newStatus = DSDocument.integratedStatus(sets)) == (prevStatus = @get('status')))
          switch newStatus
            when 'ready' then DSDigest.block load # it's only once, since 'update' is not assigned to state
            when 'update' then if @_startLoad() then @_endLoad true # process update right away
            when 'nodata' then @set 'status', 'nodata'
        return)

      @_unwatchA = people.watchStatus @, updateStatus
      @_unwatchB = tasks.watchStatus @, updateStatus

      @init = null
      return)

    @end())]
