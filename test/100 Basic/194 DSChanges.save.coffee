DSPool = require '../../src/app/dscommon/DSPool'
DSData = require '../../src/app/dscommon/DSData'
DSDocument = require '../../src/app/dscommon/DSDocument'
DSSet = require '../../src/app/dscommon/DSSet'
DSChangesBase = require '../../src/app/dscommon/DSChangesBase'

describe '194 DSChanges.save', ->

  class TestTask extends DSDocument
    @begin 'TestDoc'
    @propStr 'title', ''
    @propMoment 'duedate'
    @propDuration 'estimate'
    @propDoc 'resposible'
    @end()

  class TestPerson extends DSDocument
    @begin 'TestPerson'
    @propStr 'name', ''
    @end()

  class ServerData extends DSData
    @begin 'ServerData'
    @noCache()
    @propSet 'tasks', TestDoc
    @end()

  class Changes extends DSChangesBase
    @begin 'TestData'
    @propSet 'tasks', TestDoc.Editable
    @end()

  beforeEach (->
    window.totalReleaseReset() if window.totalRelease
    return)

  afterEach (->
    expect(_.size window.totalRelease()).toBe(0) if window.totalRelease
    return)

  it 'general', ->

