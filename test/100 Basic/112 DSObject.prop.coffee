DSObject = require '../../src/app/dscommon/DSObject'

describe '112 DSObject.prop', ->

  beforeEach (->
    window.totalReleaseReset() if window.totalRelease
    return)

  afterEach (->
    expect(_.size window.totalRelease()).toBe(0) if window.totalRelease
    return)

  it 'declare and type check', ->

    owner = {name:'owner'}

    class R extends DSObject
      @begin 'R'
      @end()

    class T extends DSObject
      @begin 'T'

      @propNum 'numNull', 0
      @propStr 'strNull', ''
      @propNum 'num', 1, ((value) -> if value > 0 then value else undefined)
      @propStr 'str', '123', ((value) -> if value != null && value.length > 0 then value else undefined)
      @propDoc 'r', R

      @end()

    t = new T owner, 'T1'

    # check getters
    expect(t._numNull).toBe(0)
    expect(t.numNull).toBe(0)
    expect((-> t.get 'numNull')()).toBe(0)

    expect(t._strNull).toBe('')
    expect(t.strNull).toBe('')
    expect((-> t.get 'strNull')()).toBe('')

    expect(t._num).toBe(1)
    expect(t.num).toBe(1)
    expect((-> t.get 'num')()).toBe(1)

    expect(t._str).toBe('123')
    expect(t.str).toBe('123')
    expect((-> t.get 'str')()).toBe('123')

    expect(t._r).toBeNull()
    expect(t.r).toBeNull()
    expect((-> t.get 'r')()).toBeNull()

    # check setters
    expect (->
      t.strNull = 0
      return)
    .toThrowError("Obj 'T:T1': Prop 'strNull': Invalid value '0'")
    expect (->
      t.numNull = ''
      return)
    .toThrowError("Obj 'T:T1': Prop 'numNull': Invalid value ''")
    expect (->
      t.set 'strNull', 0
      return)
    .toThrowError("Obj 'T:T1': Prop 'strNull': Invalid value '0'")
    expect (->
      t.set 'numNull', ''
      return)
    .toThrowError("Obj 'T:T1': Prop 'numNull': Invalid value ''")
    expect (->
      t.r = t
      return)
    .toThrowError("Obj 'T:T1': Prop 'r': Invalid value 'T:T1'")
    expect (->
      t.r = 0
      return)
    .toThrowError("Obj 'T:T1': Prop 'r': Invalid value '0'")
    expect (->
      t.get 'aaa'
      return)
    .toThrowError("Obj 'T:T1': Prop 'aaa': Invalid property")
    expect (->
      t.set 'aaa', 12
      return)
    .toThrowError("Obj 'T:T1': Prop 'aaa': Invalid property")
    expect (->
      t.str = null
      return)
    .toThrowError("Obj 'T:T1': Prop 'str': Invalid value 'null'")
    expect (->
      t.str = ''
      return)
    .toThrowError("Obj 'T:T1': Prop 'str': Invalid value ''")


    t.r = r = new R owner, 'R1'
    expect(t._r).toBe(r)
    expect(r.$ds_ref).toBe(2)
    r.release owner
    expect(r.$ds_ref).toBe(1)

    t.release owner
    expect(t.$ds_ref).toBe(0)
    expect(r.$ds_ref).toBe(0)
