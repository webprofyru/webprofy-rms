DSObject = require '../../src/app/dscommon/DSObject'

describe '114 DSObject.refCounter', ->

  beforeEach (->
    window.totalReleaseReset() if window.totalRelease
    return)

  afterEach (->
    expect(_.size window.totalRelease()).toBe(0) if window.totalRelease
    return)

  it 'addRef() and release()', ->

    ctor1 = jasmine.createSpy()

    dstr1 = jasmine.createSpy()

    class T extends DSObject
      @begin 'T'

      @ds_ctor.push ctor1

      @ds_dstr.push dstr1
      
      @end()

    owner = {name:'owner'}

    # ctor and dstr methods are called for every instance of class T
    t = new T owner, '1'

    expect(t.$ds_ref).toEqual(1)
    expect(ctor1.calls.count()).toEqual(1)
    expect(dstr1.calls.count()).toEqual(0)
    
    t.addRef owner
    expect(t.$ds_ref).toEqual(2)
    expect(ctor1.calls.count()).toEqual(1)
    expect(dstr1.calls.count()).toEqual(0)
    
    t.release owner
    expect(t.$ds_ref).toEqual(1)
    expect(ctor1.calls.count()).toEqual(1)
    expect(dstr1.calls.count()).toEqual(0)
    
    t.release owner
    expect(t.$ds_ref).toEqual(0)
    expect(ctor1.calls.count()).toEqual(1)
    expect(dstr1.calls.count()).toEqual(1)

    expect (->
      t.addRef owner # addRef() after full release
      return)
    .toThrowError('addRef() on already fully released object')

    t2 = new T owner, '2'
    expect(t2.$ds_ref).toEqual(1)
    expect(ctor1.calls.count()).toEqual(2)
    expect(dstr1.calls.count()).toEqual(1)

    t2.addRef owner
    expect(t2.$ds_ref).toEqual(2)
    expect(ctor1.calls.count()).toEqual(2)
    expect(dstr1.calls.count()).toEqual(1)

    t2.release owner
    expect(t2.$ds_ref).toEqual(1)
    expect(ctor1.calls.count()).toEqual(2)
    expect(dstr1.calls.count()).toEqual(1)

    t2.release owner
    expect(t2.$ds_ref).toEqual(0)
    expect(ctor1.calls.count()).toEqual(2)
    expect(dstr1.calls.count()).toEqual(2)

    expect (->
      t2.release owner # release() after full release
      return)
    .toThrowError('release() on already fully released object')
