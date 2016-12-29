DSObject = require '../../src/app/dscommon/DSObject'
DSPool = require '../../src/app/dscommon/DSPool'
DSData = require '../../src/app/dscommon/DSData'
DSSet = require '../../src/app/dscommon/DSSet'

describe '150 DSSet', ->

  beforeEach (->
    window.totalReleaseReset() if window.totalRelease
    return)

  afterEach (->
    expect(_.size window.totalRelease()).toBe(0) if window.totalRelease
    return)

  it 'populate', ->

    owner = {name:'owner'}

    class E extends DSObject
      @begin 'E'
      @propNum 'num', 0
      @end()

    class TestData extends DSData
      @begin 'TestData'
      @noCache()
      @propSet 'items', E
      @end()

    pool = new DSPool owner, 'poolE', E
    data = new TestData owner, 'testData', {}
    (set = data.get 'itemsSet').addRef owner
    data.release owner # data remains not deleted, case it's set is in play

    expect(data.itemsSet.$ds_ref).toBe(2)
    expect(data.$ds_ref).toBe(1)

    unwatch = set.watch owner,
      add: add = jasmine.createSpy()
      remove: remove = jasmine.createSpy()
      change: change = jasmine.createSpy()

    tmp =
      '1': e1 = pool.find owner, '1'
      '2': e2 = pool.find owner, '2'
      '3': e3 = pool.find owner, '3'

    set.merge owner, tmp

    expect(add.calls.count()).toEqual(3)
    expect(remove.calls.count()).toEqual(0)
    expect(change.calls.count()).toEqual(0)

    expect(e1.$ds_ref).toBe(1)
    expect(e2.$ds_ref).toBe(1)
    expect(e3.$ds_ref).toBe(1)

    tmp =
      '1': e1b = pool.find owner, '1'
      '3': e3b = pool.find owner, '3'
      '5': e5b = pool.find owner, '5'

    set.merge owner, tmp

    expect(add.calls.count()).toEqual(4)
    expect(remove.calls.count()).toEqual(1)
    expect(change.calls.count()).toEqual(0)

    e1.num = 0
    expect(change.calls.count()).toEqual(0)

    e1.num = 1
    expect(change.calls.count()).toEqual(1)

    expect(e1.$ds_ref).toBe(1)
    expect(e1).toBe(e1b)
    expect(e2.$ds_ref).toBe(0)
    expect(e3.$ds_ref).toBe(1)
    expect(e3).toBe(e3b)
    expect(e5b.$ds_ref).toBe(1)

    set.release owner
    unwatch()

    expect(e1.$ds_ref).toBe(0)
    expect(e3.$ds_ref).toBe(0)
    expect(e5b.$ds_ref).toBe(0)

    expect(change.calls.count()).toEqual(1)
    expect(data.$ds_ref).toBe(0)

    pool.release owner
