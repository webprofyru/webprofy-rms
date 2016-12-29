DSDocument = require '../../src/app/dscommon/DSDocument'
DSSet = require '../../src/app/dscommon/DSSet'
DSChangesBase = require '../../src/app/dscommon/DSChangesBase'

describe '174 DSDocument.DSDocumentValues', ->

  owner = {name:'owner'}

  class SomeDoc extends DSDocument
    @begin 'SomeDoc'
    @end()

  class TestDoc extends DSDocument
    @begin 'TestDoc'
    @propDoc 'docA', SomeDoc
    @propDoc 'docB', SomeDoc
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

    doc1 = new SomeDoc owner, 'doc1'
    doc2 = new SomeDoc owner, 'doc2'
    doc3 = new SomeDoc owner, 'doc3'

    srvDoc1 = new TestDoc owner, 'edtDoc1Srv'
    (edtDoc1 = new TestDoc.Editable owner, srvDoc1.$ds_key).init?(srvDoc1, set)

    edtDoc1.set 'docA', doc1

    expect(doc1.$ds_ref).toBe(3) # +1 - itself, +1 - change block, +1 - history

    edtDoc1.set 'docB', doc1

    expect(doc1.$ds_ref).toBe(5) # +1 - itself, +2 - change block, +2 - history

    edtDoc1.set 'docA', doc2 # not to be a server value

    expect(doc1.$ds_ref).toBe(5) # +1 - itself, +1 - change block, +3 - history
    expect(doc2.$ds_ref).toBe(3) # +1 - itself, +1 - change block, +1 - history

    hist.startReset()
    hist.endReset()

    expect(doc1.$ds_ref).toBe(2) # +1 - itself, +1 - change block, +0 - history

    edtDoc1.set 'docA', doc1 # not to be a server value

    expect(doc1.$ds_ref).toBe(4) # +1 - itself, +2 - change block, +1 - history

    srvDoc1.set 'docA', doc1

    expect(doc1.$ds_ref).toBe(3) # +1 - itself, +1 - change block, +0 - history, +1 - srvDoc

    srvDoc1.release owner
    edtDoc1.release owner

    doc1.release owner
    doc2.release owner
    doc3.release owner
    changes.release owner
