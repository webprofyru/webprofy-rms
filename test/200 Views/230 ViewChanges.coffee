serviceOwner = require('../../src/app/dscommon/util').serviceOwner

Task = require '../../src/app/models/Task'
DSData = require '../../src/app/dscommon/DSData'
DSDataEditable = require '../../src/app/dscommon/DSDataEditable'
DSChangesBase = require '../../src/app/dscommon/DSChangesBase'

#DSObject = require '../../src/app/dscommon/DSObject'
#DSPool = require '../../src/app/dscommon/DSPool'
#DSSet = require '../../src/app/dscommon/DSSet'

describe '230 ViewChanges', ->

  beforeEach (->
    window.totalReleaseReset() if window.totalRelease
    return)

  afterEach (->
    expect(_.size window.totalRelease).toBe(0) if window.totalRelease
    return)

  it 'check ViewChanges', ->

    owner = {name:'owner'}

    class ServerData extends DSData
      @begin 'ServerData'
      @propSet 'tasks', Task
      @end()

    class Changes extends DSChangesBase
      @begin 'TestData'
      @propSet 'tasks', Task.Editable
      @end()

    angular.mock.module require '../../src/app/ui/views/changes/ViewChanges'
    angular.mock.module (($provide) ->
      $provide.factory 'dsDataService', (() ->
        return {
          requestSources: ((referry, params, sources) ->

            console.info 'requestSources'

            serviceOwner.add(serverData = new ServerData serviceOwner, 'serverData', {})
            serviceOwner.add(changes = new Changes serviceOwner, 'changes')

            set = {}
            task1 = Task.pool.find(owner, '111', set)
            task1.set 'duedate', moment('2015-02-14')
            task1.set 'estimate', moment.duration(2, 'h')
            task2 = Task.pool.find(owner, '222', set)
            task2.set 'duedate', moment('2015-02-14')
            task2.set 'estimate', moment.duration(2, 'h')
            serverData.get('tasksSet').merge owner, set
            serverData.get('tasksSet').set 'status', 'ready'

            changes.get('tasksSet').set 'status', 'ready'

            (dataEditable = new (DSDataEditable(changes.tasksSet.type))(serviceOwner, 'editedData', {}))
            .init?(serverData.tasksSet, changes.tasksSet)
            serviceOwner.add(dataEditable)

            expect(task1Editable = dataEditable.get('items')['111']).toBeDefined()
            task1Editable.set 'estimate', moment.duration(1, 'd')

            expect(task2Editable = dataEditable.get('items')['222']).toBeDefined()
            task2Editable.set 'duedate', moment('2015-03-01')
            task2Editable.set 'estimate', moment.duration(15, 'min')

            (sources.tasks.newSet = changes.get('tasksSet')).addRef(referry)

            return)})
      return)

    inject (ViewChanges, $rootScope, $httpBackend) ->

      $httpBackend.expectGET('data/people.json').respond '{}'

      view = new ViewChanges($scope = $rootScope.$new(false, $rootScope), 'view')
      $rootScope.$digest(); # let render to work

      expect(_.size(tasks = view.get('data').get('tasks'))).toBe(2)
      expect(task1 = tasks['111']).toBeDefined()
      expect(task2 = tasks['222']).toBeDefined()

      expect(view.get('changes').length).toBe(3)

      $scope.$destroy()
