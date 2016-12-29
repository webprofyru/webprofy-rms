DSObject = require '../../src/app/dscommon/DSObject'

describe '110 DSObject.beginEnd.coffee', ->

  beforeEach (->
    window.totalReleaseReset() if window.totalRelease
    return)

  afterEach (->
    expect(_.size window.totalRelease()).toBe(0) if window.totalRelease
    return)

  it 'construct and destroy an Object', ->

    owner = {name:'owner'}

    ctor1 = jasmine.createSpy()
    ctor2 = jasmine.createSpy()

    dstr1 = jasmine.createSpy()
    dstr2 = jasmine.createSpy()

    class T extends DSObject
      @begin 'T'

      @ds_ctor.push ctor1
      @ds_ctor.push ctor2

      @ds_dstr.push dstr1
      @ds_dstr.push dstr2

      @end()

    # ctor and dstr methods are called for every instance of class T
    t = new T owner, '1'
    expect(ctor1).toHaveBeenCalled()
    expect(ctor2).toHaveBeenCalled()
    expect(dstr1).not.toHaveBeenCalled()
    expect(dstr2).not.toHaveBeenCalled()

    t.release owner
    expect(dstr1).toHaveBeenCalled()
    expect(dstr2).toHaveBeenCalled()

    t2 = new T owner, '2'
    expect(ctor1.calls.count()).toEqual(2)
    expect(ctor2.calls.count()).toEqual(2)
    expect(dstr1.calls.count()).toEqual(1)
    expect(dstr2.calls.count()).toEqual(1)
    t2.release owner
    expect(ctor1.calls.count()).toEqual(2)
    expect(ctor2.calls.count()).toEqual(2)
    expect(dstr1.calls.count()).toEqual(2)
    expect(dstr2.calls.count()).toEqual(2)

    # ctor and dstr methotds of class T are not called for another class
    class AnotherClass extends DSObject
      @begin 'AnotherClass'
      @end()

    ac = new AnotherClass owner, 'A'
    expect(ctor1.calls.count()).toEqual(2)
    expect(ctor2.calls.count()).toEqual(2)
    expect(dstr1.calls.count()).toEqual(2)
    expect(dstr2.calls.count()).toEqual(2)

    ac.release owner
    expect(ctor1.calls.count()).toEqual(2)
    expect(ctor2.calls.count()).toEqual(2)
    expect(dstr1.calls.count()).toEqual(2)
    expect(dstr2.calls.count()).toEqual(2)

    # TODO: Consider adding child class with another methods
