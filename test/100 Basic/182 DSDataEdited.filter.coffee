DSPool = require '../../src/app/dscommon/DSPool'
DSData = require '../../src/app/dscommon/DSData'
DSDataEditable = require '../../src/app/dscommon/DSDataEditable'
DSDocument = require '../../src/app/dscommon/DSDocument'
DSSet = require '../../src/app/dscommon/DSSet'
DSChangesBase = require '../../src/app/dscommon/DSChangesBase'

describe '182 DSDataEdited.filter', ->

  owner = {name:'owner'}

  class TestDoc extends DSDocument
    @begin 'TestDoc'
    @addPool()
    @propNum 'num', 0
    @end()

  class ServerData extends DSData
    @begin 'ServerData'
    @noCache()
    @propSet 'items', TestDoc
    @end()

  class Changes extends DSChangesBase
    @begin 'TestData'
    @propSet 'items', TestDoc.Editable
    @end()

  beforeEach (->
    window.totalReleaseReset() if window.totalRelease
    return)

  afterEach (->
    expect(_.size window.totalRelease()).toBe(0) if window.totalRelease
    return)

  it 'general', ->

    serverData = new ServerData owner, 'serverData', {}
    changes = new Changes owner, 'changes'; changes.itemsSet.status = 'ready'

    (dataEditable = new (DSDataEditable(changes.itemsSet.type))(owner, 'editedData', {from: 10, to: 20}))
    .init?(serverData.itemsSet, changes.itemsSet, ((v) -> return @params.from <= v.get('num') < @params.to))

    doc1 = TestDoc.pool.find owner, 'doc1'; doc1.set 'num', 10
    doc2 = TestDoc.pool.find owner, 'doc2'; doc2.set 'num', 5
    doc3 = TestDoc.pool.find owner, 'doc3'; doc3.set 'num', 15

    serverData.itemsSet.add owner, doc1
    serverData.itemsSet.add owner, doc2
    serverData.itemsSet.add owner, doc3
    serverData.itemsSet.status = 'ready'

    expect(_.size dataEditable.items).toBe(3)
    expect(doc1Editable = dataEditable.items['doc1']).toBeDefined()
    expect(doc2Editable = dataEditable.items['doc2']).toBeDefined()
    expect(doc3Editable = dataEditable.items['doc3']).toBeDefined()

    doc2Editable.set 'num', 12
    expect(_.size dataEditable.items).toBe(3)
    expect(_.size changes.items).toBe(1)

    doc3Editable.set 'num', 18
    expect(_.size dataEditable.items).toBe(3)
    expect(_.size changes.items).toBe(2)

    serverData.itemsSet.remove doc2
    expect(_.size dataEditable.items).toBe(3)
    expect(_.size changes.items).toBe(2)

    doc2Editable.set 'num', 25 # out of range
    expect(_.size dataEditable.items).toBe(2)
    expect(_.size changes.items).toBe(2)

    doc3.set 'num', 18 # no changes
    expect(_.size dataEditable.items).toBe(2)
    expect(_.size changes.items).toBe(1)

    dataEditable.release owner
    serverData.release owner
    changes.release owner
