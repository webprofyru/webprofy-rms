assert = require('../../../dscommon/util').assert
error = require('../../../dscommon/util').error

DSDocument = require('../../../dscommon/DSDocument')

module.exports = class TaskSplit
  @addPropType = ((clazz) ->
    clazz.propTaskRelativeSplit = ((name, valid) ->
      if assert
        error.invalidArg 'name'if !typeof name == 'string'
        error.invalidArg 'valid' if valid && typeof valid != 'function'
      valid = if q = valid then ((value) -> return if (value == null || (typeof value == 'object' && value instanceof TaskSplit)) && q(value) then value else undefined)
      else ((value) -> return if value == null || value instanceof TaskSplit then value else undefined)
      return clazz.prop {
        name
        type: 'taskRelativeSplit'
        valid
        read: ((v) -> if v != null then new TaskSplit(v) else null)
        str: ((v) -> if v then 'split' else '')
        equal: ((l, r) ->
          return l == r if l == null || r == null
          return false if (leftList = l?.list).length != (rightList = r?.list).length
          for v, i in leftList by 2
            if v != rightList[i] || leftList[i + 1].valueOf() != rightList[i + 1].valueOf()
              return false
          return true)
        init: null})
    return)

  zero = moment.duration(0)

  constructor: ((persisted) ->
    if assert
      if arguments.length == 1 && typeof arguments[0] == 'object' && arguments[0].__proto__ == TaskSplit::
        undefined
      else if arguments.length == 1 && Array.isArray persisted
        error.invalidArg 'persisted' if !(persisted.length % 2 == 0)
        error.invalidArg 'persisted' for v in persisted when !(typeof v == 'number')
    if arguments.length == 1 && typeof (src = arguments[0]) == 'object' && src.__proto__ == TaskSplit::
      @list = src.list.slice()
    else
      @list = list = []
      if Array.isArray persisted
        for d, i in persisted by 2
          list.push moment.duration(d, 'day').valueOf()
          list.push moment.duration(persisted[i + 1], 'minute')
    return)

  clone: (-> return new TaskSplit(@))

  set: ((duedate, date, estimate) ->
    if assert
      error.invalidArg 'duedate' if !(moment.isMoment duedate)
      error.invalidArg 'date' if !(moment.isMoment date)
      error.invalidArg 'estimate' if !(estimate == null || moment.isDuration estimate)
    dateDiff = date.diff duedate
    for d, i in (list = @list) by 2
      if d == dateDiff
        if estimate != null && estimate.valueOf() != 0
          return if list[i + 1].valueOf() == estimate.valueOf()
          list[i + 1] = estimate
        else
          list.splice i, 2
        delete @value
        return
      else if dateDiff < d
        list.splice i, 0, dateDiff, estimate if estimate?.valueOf() != 0
        delete @value
        return
    if estimate?.valueOf() != 0
      delete @value
      list.push dateDiff
      list.push estimate
    return @)

  get: ((duedate, date) ->
    if assert
      error.invalidArg 'duedate' if !(moment.isMoment duedate)
      error.invalidArg 'date' if !(moment.isMoment date)
    dateDiff = date.diff duedate
    return list[i + 1] for d, i in (list = @list) by 2 when d == dateDiff
    return null)

  day: ((getDuedate, date) -> # It's angular frendly accessor to be used by ng-models
    if assert
      error.invalidArg 'getDuedate' if !typeof getDuedate == 'function'
      error.invalidArg 'date' if !moment.isMoment(date)
    Object.defineProperty accessor = {}, 'val',
      get: (=> @get(getDuedate(), date))
      set: ((v) => @set(getDuedate(), date, v))
    return accessor)

  valueOf: (->
    return value if (value = @value)
    @value = res = []
    for s, i in (list = @list) by 2
      e = list[i + 1]
      res.push moment.duration(s).asDays()
      res.push e.asMinutes()
    return res)

  shift: ((newDuedate, oldDuedate) ->
    if assert
      switch arguments.length
        when 1 then error.invalidArg 'diff' unless typeof newDuedate == 'number'
        when 2
          error.invalidArg 'newDuedate' unless moment.isMoment(newDuedate)
          error.invalidArg 'oldDuedate' unless moment.isMoment(oldDuedate)
        else throw new Error 'Invalid arguments'
    delete @value
    diff = if typeof newDuedate == 'number' then newDuedate else newDuedate.diff oldDuedate
    if diff != 0
      list[i] -= diff for t, i in (list = @list) by 2
    return)

  firstDate: ((duedate) ->
    if assert
      error.invalidArg 'duedate' if !moment.isMoment(duedate)
    return if (list = @list).length > 0 then moment(duedate).add(list[0]) else null)

  lastDate: ((duedate) ->
    if assert
      error.invalidArg 'duedate' if !moment.isMoment(duedate)
    return if (list = @list).length > 0 then moment(duedate).add(list[list.length - 2]) else null)

  clear: (->
    delete @value
    @list = []
    return)

  fixEstimate: ((diff) ->
    if diff > 0
      # Rule: not splitted time is added to last split date
      @list[@list.length - 1].add diff
    else if diff < 0
      # Rule: Extra splitted time is removed from begging of split
      for s, i in list = @list[1..] by 2
        if (diff += s.valueOf()) > 0
          @list[i + 1] = moment.duration diff
          @list = @list.slice (i)
          break
    return)

  Object.defineProperty @::, 'total',
    get: (->
      return zero if (list = @list).length == 0
      return list[1] if list.length == 1
      sum = moment.duration(list[1])
      sum.add(t) for t in list[3..] by 2
      return sum)
