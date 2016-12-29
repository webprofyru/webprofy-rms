DSObject = require '../../src/app/dscommon/DSObject'
DSPool = require '../../src/app/dscommon/DSPool'
DSList = require '../../src/app/dscommon/DSList'

describe '160 DSList', ->

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

    pool = new DSPool owner, 'poolA', E
    list = new DSList owner, 'listA', E

    tmp = [
      e1 = pool.find owner, '1'
      e2 = pool.find owner, '2'
      e3 = pool.find owner, '3']

    list.merge owner, tmp

    expect(e1.$ds_ref).toBe(1)
    expect(e2.$ds_ref).toBe(1)
    expect(e3.$ds_ref).toBe(1)

    tmp = [
      e1b = pool.find owner, '1'
      e3b = pool.find owner, '3'
      e5b = pool.find owner, '5']

    list.merge owner, tmp

    expect(e1.$ds_ref).toBe(1)
    expect(e1).toBe(e1b)
    expect(e2.$ds_ref).toBe(0)
    expect(e3.$ds_ref).toBe(1)
    expect(e3).toBe(e3b)
    expect(e5b.$ds_ref).toBe(1)

    list.release owner

    expect(e1.$ds_ref).toBe(0)
    expect(e3.$ds_ref).toBe(0)
    expect(e5b.$ds_ref).toBe(0)

    pool.release owner
