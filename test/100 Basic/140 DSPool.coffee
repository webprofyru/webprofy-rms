DSObject = require '../../src/app/dscommon/DSObject'
DSPool = require '../../src/app/dscommon/DSPool'

describe '140 DSPool', ->

  beforeEach (->
    window.totalReleaseReset() if window.totalRelease
    return)

  afterEach (->
    expect(_.size window.totalRelease()).toBe(0) if window.totalRelease
    return)

  it 'create, reuse, release', ->

    owner = {name:'owner'}

    class E extends DSObject
      @begin 'E'
      @end()

    pool = new DSPool owner, 'poolA', E

    e1 = pool.find owner, '1'
    expect(e1).not.toBeNull()

    e2 = pool.find owner, '2'
    expect(e2).not.toBeNull()

    e1b = pool.find owner, '1'
    expect(e1b).not.toBeNull()
    expect(e1b).toBe(e1)

    e1.release owner
    e1b.release owner

    e1c = pool.find owner, '1'
    expect(e1c).not.toBeNull()
    expect(e1c).not.toBe(e1)

    e1c.release owner
    e2.release owner
    pool.release owner

