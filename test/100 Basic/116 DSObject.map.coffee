DSObject = require '../../src/app/dscommon/DSObject'

describe '116 DSObject.map', ->

  owner = {name:'owner'}

  class AnotherDoc extends DSObject
    @begin 'AnotherDoc'
    @end()

  class TestDoc extends DSObject
    @begin 'TestDoc'

    @propNum 'num', 12
    @propStr 'str', 'TestStr'
    @propBool 'bool', false
    @propObj 'obj', {}
    @propDoc 'doc', AnotherDoc
    @propMoment 'moment'
    @propDuration 'duration'

    constructor: ((referry, key) ->
      DSObject.call @, referry, key
      @set 'doc', anotherDoc = new AnotherDoc(owner, 'anotherDoc'); anotherDoc.release owner
      @set 'moment', moment('2015-02-18')
      @set 'duration', moment.duration('2h')
      return)

    @end()

  beforeEach (->
    window.totalReleaseReset() if window.totalRelease
    return)

  afterEach (->
    expect(_.size window.totalRelease()).toBe(0) if window.totalRelease
    return)

  it 'DSObject to simple map and back', ->

    expect(mapA = (testDoc = new TestDoc(owner, 'testDoc')).writeMap()).toEqual({
      num: 12
      str: 'TestStr'
      bool: false
      obj: {}
      doc: 'anotherDoc'
      moment: moment('2015-02-18').valueOf()
      duration: moment.duration('2h').valueOf()
    })

    testDoc.num = null
    testDoc.str = null
    testDoc.bool = null
    testDoc.obj = null
    testDoc.doc = null
    testDoc.moment = null
    testDoc.duration = null

    expect(mapB = testDoc.writeMap()).toEqual({
      num: null
      str: null
      bool: null
      obj: null
      doc: null
      moment: null
      duration: null
    })

    testDoc.readMap(mapA)
    expect(testDoc.num).toBe(12)
    expect(testDoc.str).toBe('TestStr')
    expect(testDoc.bool).toBe(false)
    expect(testDoc.obj).toEqual({})
    expect(testDoc.doc).toBeNull()
    expect(testDoc.moment.valueOf()).toBe(moment('2015-02-18').valueOf())
    expect(testDoc.duration.valueOf()).toBe(moment.duration('2h').valueOf())

    testDoc.readMap(mapB)
    expect(testDoc.num).toBeNull()
    expect(testDoc.str).toBeNull()
    expect(testDoc.bool).toBeNull()
    expect(testDoc.obj).toBeNull()
    expect(testDoc.doc).toBeNull()
    expect(testDoc.moment).toBeNull()
    expect(testDoc.duration).toBeNull()

    testDoc.release owner
