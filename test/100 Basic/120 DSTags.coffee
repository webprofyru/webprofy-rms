DSTags = require '../../src/app/dscommon/DSTags'

describe '120 DSTags', ->

  it 'general', ->

    e1 = new DSTags 'c, b'
    e2 = e1.clone()
    e3 = e2.clone()

    expect(e1.get('c')).toBeTruthy()
    expect(e1.get('b')).toBeTruthy()
    expect(e1.get('a')).toBeFalsy()

    e1.set 'b', false
    expect(e1.get('b')).toBeFalsy()

    e1.set 'a', true
    expect(e1.get('a')).toBeTruthy()

    expect(e1).not.toEqual(e2)
    expect(e2).toEqual(e3)

    expect(e1.valueOf()).toBe('a,c')
    expect(e1.diff(e2)).toBe('+a, -b')

    # TODO: Later consider diff localization


