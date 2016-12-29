assert = require('../../dscommon/util').assert
error = require('../../dscommon/util').error

DSObject = require '../../dscommon/DSObject'

Person = require './Person'

module.exports = class PersonDayStat extends DSObject
  @begin 'PersonDayStat'

  @DayStat = class DayStat extends DSObject
    @begin 'DayStat'
    @propMoment 'day'
    @propNum 'tasksCount'
    @propDuration 'contract' # time person expected to work by contract
    @propDuration 'tasksTotal' # total time of tasks planned for this person for this day
    @propDuration 'timeLeft' # = contract - tasksTotal, can be negative
    @propDuration 'timeSpent' # work time report by worker.  Note: This field gets populate right in View1 logic
    @end()

  constructor: ((referry, key, person, days) ->
    DSObject.call @, referry, key
    if assert
      error.invalidArg 'person' if !(person instanceof Person)
      error.invalidArg 'days' if !(Array.isArray days)
      error.invalidArg 'days' for d in days when !moment.isMoment(d)
    @set 'person', person
    id = 0
    @get('dayStatsList').merge @, (((ds = new DayStat @, "#{id++}").set('day', d); ds) for d in days)
    return)

  @propDoc 'person', Person
  @propList 'dayStats', DayStat
  @propDuration 'totalPeriodTime'

  @end()

