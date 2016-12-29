DSDocument = require '../../src/app/dscommon/DSDocument'
DSSet = require '../../src/app/dscommon/DSSet'
DSChangesBase = require '../../src/app/dscommon/DSChangesBase'

describe '170 DSDocument', ->

  owner = {name:'owner'}

  class TestDoc extends DSDocument
    @begin 'TestDoc'
    @propStr 'name'
    @propBool 'deleted', false
    # TODO: Add DSObject ref
    @end()

  class TestData extends DSChangesBase
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

    changes = new TestData owner, 'changes', {}
    hist = changes.get('hist')
    set = changes.get('itemsSet')

    srvDoc = new TestDoc owner, 'srvDoc', set
    srvDoc.set 'name', 'doc1'
    expect(_.size set.items).toBe(0)

    (edtDoc = new TestDoc.Editable owner, srvDoc.$ds_key).init?(srvDoc, set)
    expect(srvDoc.$ds_ref).toBe(2)
    expect(_.size set.items).toBe(0)
    srvDoc.release owner
    expect(srvDoc.$ds_ref).toBe(1)

    expect(edtDoc.get 'name').toBe('doc1')
    expect(edtDoc.get 'deleted').toBe(false)
    expect(_.size set.items).toBe(0)

    edtDoc.set 'name', 'newName'
    expect(_.size set.items).toBe(1)
    expect(srvDoc.get 'name').toBe('doc1')
    expect(edtDoc.get 'name').toBe('newName')
    expect(hist.hist).toEqual [{i: edtDoc, p: 'name', o: undefined, n: 'newName'}]
    expect(hist.histTop).toBe(1)

    edtDoc.set 'deleted', true
    expect(_.size set.items).toBe(1)
    expect(srvDoc.get 'deleted').toBe(false)
    expect(edtDoc.get 'name').toBe('newName')
    expect(edtDoc.__change).toEqual(
      name: {v: 'newName', s: 'doc1'}
      deleted: {v: true, s: false})
    expect(hist.hist).toEqual [
      {i: edtDoc, p: 'name', o: undefined, n: 'newName'}
      {i: edtDoc, p: 'deleted', o: undefined, n: true}]
    expect(hist.histTop).toBe(2)

    edtDoc.set 'deleted', false
    edtDoc.set 'name', 'doc1'
    expect(_.size set.items).toBe(0)
    expect(edtDoc.__change).toBeUndefined()
    expect(hist.hist).toEqual [
      {i: edtDoc, p: 'name', o: undefined, n: 'newName'}
      {i: edtDoc, p: 'deleted', o: undefined, n: true}
      {i: edtDoc, p: 'deleted', o: true, n: undefined}
      {i: edtDoc, p: 'name', o: 'newName', n: undefined}]
    expect(hist.histTop).toBe(4)

    expect(hist.hasUndo()).toBeTruthy()
    expect(hist.hasRedo()).toBeFalsy()

    hist.undo()
    expect(hist.hasUndo()).toBeTruthy()
    expect(hist.hasRedo()).toBeTruthy()
    expect(hist.hist).toEqual [
      {i: edtDoc, p: 'name', o: undefined, n: 'newName'}
      {i: edtDoc, p: 'deleted', o: undefined, n: true}
      {i: edtDoc, p: 'deleted', o: true, n: undefined}
      {i: edtDoc, p: 'name', o: 'newName', n: undefined}]
    expect(hist.histTop).toBe(3)

    hist.redo()
    expect(hist.hasUndo()).toBeTruthy()
    expect(hist.hasRedo()).toBeFalsy()
    expect(hist.hist).toEqual [
      {i: edtDoc, p: 'name', o: undefined, n: 'newName'}
      {i: edtDoc, p: 'deleted', o: undefined, n: true}
      {i: edtDoc, p: 'deleted', o: true, n: undefined}
      {i: edtDoc, p: 'name', o: 'newName', n: undefined}]
    expect(hist.histTop).toBe(4)

    hist.undo()
    hist.undo()
    hist.undo()
    expect(_.size set.items).toBe(1)
    expect(edtDoc.$ds_ref).toBe(6)
    hist.undo()
    expect(_.size set.items).toBe(0)
    expect(edtDoc.$ds_ref).toBe(5)
    expect(hist.hasUndo()).toBeFalsy()
    expect(hist.hasRedo()).toBeTruthy()

    hist.redo()
    hist.redo()
    expect(hist.hist).toEqual [
      {i: edtDoc, p: 'name', o: undefined, n: 'newName'}
      {i: edtDoc, p: 'deleted', o: undefined, n: true}
      {i: edtDoc, p: 'deleted', o: true, n: undefined}
      {i: edtDoc, p: 'name', o: 'newName', n: undefined}]
    expect(hist.histTop).toBe(2)
    expect(_.size set.items).toBe(1)
    expect(edtDoc.$ds_ref).toBe(6)

    edtDoc.set 'name', 'name2'
    expect(hist.histTop).toBe(3)
    expect(hist.hist).toEqual [
      {i: edtDoc, p: 'name', o: undefined, n: 'newName'}
      {i: edtDoc, p: 'deleted', o: undefined, n: true}
      {i: edtDoc, p: 'name', o: 'newName', n: 'name2'}]
    expect(_.size set.items).toBe(1)
    expect(edtDoc.$ds_ref).toBe(5) # -1 case history trunketed

    edtDoc.release owner
    expect(edtDoc.$ds_ref).toBe(4) # it's history, why not five?!?
    expect(srvDoc.$ds_ref).toBe(1)

    changes.reset()
    expect(edtDoc.$ds_ref).toBe(0)
    expect(srvDoc.$ds_ref).toBe(0)

    changes.release owner