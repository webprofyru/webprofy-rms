TaskSplit = require '../../src/app/models/types/TaskSplit'

describe '310 TaskSplit', ->

  it 'general', ->

    taskSplit = new TaskSplit()

    duedate = moment('2015-03-04')
    duedateShifted = moment('2015-03-06')

    taskSplit.set duedate, moment('2015-03-03'), moment.duration(2, 'h')
    taskSplit.set duedate, moment('2015-03-05'), moment.duration(3, 'h')
    taskSplit.set duedate, moment('2015-03-06'), moment.duration(4, 'h')

    expect(taskSplit.get duedate, moment('2015-03-02')).toBeNull()
    expect(taskSplit.get duedate, moment('2015-03-03')).toEqual(moment.duration(2, 'h'))
    expect(taskSplit.get duedate, moment('2015-03-04')).toBeNull()
    expect(taskSplit.get duedate, moment('2015-03-05')).toEqual(moment.duration(3, 'h'))
    expect(taskSplit.get duedate, moment('2015-03-06')).toEqual(moment.duration(4, 'h'))
    expect(taskSplit.get duedate, moment('2015-03-07')).toBeNull()

    # dates shift +2 days
    expect(taskSplit.get duedateShifted, moment('2015-03-04')).toBeNull()
    expect(taskSplit.get duedateShifted, moment('2015-03-05')).toEqual(moment.duration(2, 'h'))
    expect(taskSplit.get duedateShifted, moment('2015-03-06')).toBeNull()
    expect(taskSplit.get duedateShifted, moment('2015-03-07')).toEqual(moment.duration(3, 'h'))
    expect(taskSplit.get duedateShifted, moment('2015-03-08')).toEqual(moment.duration(4, 'h'))
    expect(taskSplit.get duedateShifted, moment('2015-03-09')).toBeNull()

    expect(taskSplit.total).toEqual(moment.duration(9, 'h'))
    expect(taskSplit.get duedate, moment('2015-03-03')).toEqual(moment.duration(2, 'h')) # check it was not danaged by 'total'

    expect(taskSplit.firstDate(duedate).valueOf()).toBe(moment('2015-03-03').valueOf())
    expect(taskSplit.lastDate(duedate).valueOf()).toBe(moment('2015-03-06').valueOf())

    clone = taskSplit.clone()
    expect(clone).toEqual(taskSplit)

    expect(taskSplit.valueOf()).toEqual([
      moment.duration(moment('2015-03-03').diff(duedate)).asDays(), moment.duration(2, 'h').asMinutes(),
      moment.duration(moment('2015-03-05').diff(duedate)).asDays(), moment.duration(3, 'h').asMinutes(),
      moment.duration(moment('2015-03-06').diff(duedate)).asDays(), moment.duration(4, 'h').asMinutes()])

    expect((new TaskSplit(taskSplit.valueOf())).valueOf()).toEqual(taskSplit.valueOf())

    taskSplit.set duedate, moment('2015-03-03'), moment.duration(0)
    taskSplit.set duedate, moment('2015-03-06'), null
    expect(taskSplit.firstDate(duedate).format()).toEqual(moment('2015-03-05').format())
    expect(taskSplit.lastDate(duedate).format()).toEqual(moment('2015-03-05').format())
    expect(taskSplit.firstDate(duedateShifted).format()).toEqual(moment('2015-03-07').format())
    expect(taskSplit.lastDate(duedateShifted).format()).toEqual(moment('2015-03-07').format())
    expect(clone).not.toEqual(taskSplit)

    expect(taskSplit.total).toEqual(moment.duration(3, 'h'))

    expect(taskSplit.firstDate(duedate).startOf('week').valueOf()).toBe(moment('2015-03-02').valueOf()) # this values generally are equal, but their inner fields are not the same
    expect(taskSplit.lastDate(duedate).endOf('week').valueOf()).toBe(moment('2015-03-08T23:59:59.999').valueOf())

    clone.shift duedateShifted, duedate
    # days remains as for original duedate
    expect(clone.get duedateShifted, moment('2015-03-02')).toBeNull()
    expect(clone.get duedateShifted, moment('2015-03-03')).toEqual(moment.duration(2, 'h'))
    expect(clone.get duedateShifted, moment('2015-03-04')).toBeNull()
    expect(clone.get duedateShifted, moment('2015-03-05')).toEqual(moment.duration(3, 'h'))
    expect(clone.get duedateShifted, moment('2015-03-06')).toEqual(moment.duration(4, 'h'))
    expect(clone.get duedateShifted, moment('2015-03-07')).toBeNull()

