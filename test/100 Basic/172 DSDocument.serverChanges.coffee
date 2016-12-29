DSDocument = require '../../src/app/dscommon/DSDocument'
DSSet = require '../../src/app/dscommon/DSSet'
DSChangesBase = require '../../src/app/dscommon/DSChangesBase'

describe '172 DSDocument.serverChanges', ->

  owner = {name:'owner'}

  class TestDoc extends DSDocument
    @begin 'TestDoc'
    @propStr 'name'
    @propNum 'num', 0
    @propBool 'deleted', false
    @end()

  class Changes extends DSChangesBase
    @begin 'Changes'
    @propSet 'items', TestDoc.Editable
    @end()

  beforeEach (->
    window.totalReleaseReset() if window.totalRelease
    return)

  afterEach (->
    expect(_.size window.totalRelease()).toBe(0) if window.totalRelease
    return)

  it 'general', ->

    changes = new Changes owner, 'changes', {}
    hist = changes.get('hist')
    set = changes.get('itemsSet')

    srvDoc = new TestDoc owner, 'srvDoc', set
    srvDoc.set 'name', 'doc1'

    (edtDoc = new TestDoc.Editable owner, srvDoc.$ds_key).init?(srvDoc, set)
    edtDoc.set 'name', 'newName'

    edtDoc.set 'name', 'anotherName'

    edtDoc.set 'name', 'newName'
    edtDoc.set 'deleted', true
    edtDoc.set 'num', 10

    expect(hist.hist).toEqual [
      {i: edtDoc, p: 'name', o: undefined, n: 'newName'}
      {i: edtDoc, p: 'name', o: 'newName', n: 'anotherName'}
      {i: edtDoc, p: 'name', o: 'anotherName', n: 'newName'}
      {i: edtDoc, p: 'deleted', o: undefined, n: true}
      {i: edtDoc, p: 'num', o: undefined, n: 10}]
    expect(hist.histTop).toBe(5)

    srvDoc.set 'name', 'newName'
    srvDoc.set 'deleted', true

    expect(hist.hist).toEqual [
      {i: edtDoc, p: 'name', o: undefined, n: 'newName'}
      {i: edtDoc, p: 'name', o: 'newName', n: 'anotherName'}
      {i: edtDoc, p: 'name', o: 'anotherName', n: undefined}
      {i: edtDoc, p: 'num', o: undefined, n: 10}]
    expect(hist.histTop).toBe(4)

    expect(_.size set.items).toBe(1)
    srvDoc.set 'num', 10
    expect(hist.hist).toEqual [
      {i: edtDoc, p: 'name', o: undefined, n: 'newName'}
      {i: edtDoc, p: 'name', o: 'newName', n: 'anotherName'}
      {i: edtDoc, p: 'name', o: 'anotherName', n: undefined}]
    expect(hist.histTop).toBe(3)
    expect(_.size set.items).toBe(0)

    srvDoc.release owner
    edtDoc.release owner
    changes.release owner
