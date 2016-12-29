DSPool = require '../../src/app/dscommon/DSPool'
DSData = require '../../src/app/dscommon/DSData'
DSDataEditable = require '../../src/app/dscommon/DSDataEditable'
DSDocument = require '../../src/app/dscommon/DSDocument'
DSSet = require '../../src/app/dscommon/DSSet'
DSChangesBase = require '../../src/app/dscommon/DSChangesBase'

describe '192 DSChanges.persistAndRestore', ->

  owner = {name:'owner'}

  class TestPerson extends DSDocument
    @begin 'TestPerson'
    @propStr 'name', ''
    @end()

  class TestTask extends DSDocument
    @begin 'TestTask'
    @addPool()
    @propStr 'title', ''
    @propMoment 'duedate'
    @propDuration 'estimate'
    @propDoc 'resposible', TestPerson
    @end()

  class ServerData extends DSData
    @begin 'ServerData'
    @noCache()
    @propSet 'tasks', TestTask
    @end()

  class Changes extends DSChangesBase
    @begin 'TestData'
    @propSet 'tasks', TestTask.Editable
    @end()

  beforeEach (->
    window.totalReleaseReset() if window.totalRelease
    return)

  afterEach (->
    expect(_.size window.totalRelease()).toBe(0) if window.totalRelease
    return)

  it 'general', ->

    poolEditable = new DSPool owner, 'poolEditable', TestTask.Editable
    serverData = new ServerData owner, 'serverData', {}
    changes = new Changes owner, 'changes'; changes.tasksSet.status = 'ready'

    (dataEditable = new (DSDataEditable(changes.tasksSet.type))(owner, 'dataEditable', {}))
    .init?(serverData.tasksSet, changes.tasksSet)

    testPerson = new TestPerson owner, 'testPerson'

    # create server data
    map = {}

    task1 = TestTask.pool.find owner, 'task1', map
    task1.set 'title', 'task1'
    task1.set 'duedate', moment('2015-01-10')
    task1.set 'estimate', moment.duration('1h')
    task1.set 'resposible', testPerson

    task2 = TestTask.pool.find owner, 'task2', map
    task2.set 'title', 'task2'
    task2.set 'duedate', null
    task2.set 'estimate', null
    task2.set 'resposible', null

    serverData.tasksSet.merge owner, map
    serverData.tasksSet.status = 'ready'

    # make few modifications
    expect(task1Edited = changes.tasksSet.$ds_pool.items[task1.$ds_key]).toBeDefined()
    task1Edited.set 'title', 'task1bis'
    task1Edited.set 'duedate', null
    task1Edited.set 'estimate', null
    task1Edited.set 'resposible', null

    expect(task2Edited = changes.tasksSet.$ds_pool.items[task2.$ds_key]).toBeDefined()
    task2Edited.set 'duedate', moment('2015-02-01')
    task2Edited.set 'estimate', moment.duration('15h')
    task2Edited.set 'resposible', testPerson

    # ...and lets persist
    # TODO: Consider removing changes.persis, since I still need to conver changes-maps to valueOf values

    console.info 'changes: ', map = changes.changesToMap()

    console.info 'back: ', chg = changes.mapToChanges(map)

    poolEditable.release owner
    serverData.release owner
    changes.release owner
    dataEditable.release owner
    testPerson.release owner
