DSObject = require '../../src/app/dscommon/DSObject'
DSPool = require '../../src/app/dscommon/DSPool'
DSSet = require '../../src/app/dscommon/DSSet'
DSData = require '../../src/app/dscommon/DSData'

describe '220 View.IntegratedStatus', ->

  # TODO: Test integrated state
  # TODO: Test dataUpdate method - no set change, with set change
  # TODO: Multiple set update with one is editable another is not

  beforeEach (->
    window.totalReleaseReset() if window.totalRelease
    return)

  afterEach (->
    expect(_.size window.totalRelease).toBe(0) if window.totalRelease
    return)

  it 'react on data load and changes', ->

    owner = {name:'owner'}

    class Model extends DSObject
      @begin 'Model'
      @addPool()
      @propStr 'text'
      @end()

    class ModelData extends DSData
      @begin 'TestData'
      @noCache()
      @propSet 'set1', Model
      @propSet 'set2', Model
      @propSet 'set3', Model
      @end()

    angular.mock.module require '../../src/app/dscommon/DSView'
    angular.mock.module (($provide) ->
      $provide.factory 'dsDataService', (() ->
        data = new ModelData owner, 'data', {}
        dataCounter = 0
        return {
          _dataCounter: (-> dataCounter)
          _data: data
          _set1: set1 = data.get 'set1Set'
          _set2: set2 = data.get 'set2Set'
          _set3: set3 = data.get 'set3Set'
          _setStatus: ((set1Status, set2Status, set3Status) ->
            set1.set 'status', set1Status
            set2.set 'status', set2Status
            set3.set 'status', set3Status
            return)
          requestSources: ((owner, params, sources) ->
            sources.models1.newSet = set1; set1.addRef owner
            sources.models2.newSet = set2; set2.addRef owner
            sources.models3.newSet = set3; set3.addRef owner
            dataCounter += 3
            return)})
      return)

    inject (DSView, dsDataService, $rootScope, $httpBackend) ->

      $httpBackend.expectGET('data/people.json').respond '{}'

      class TestView extends DSView
        @begin 'TestView'
        @propData 'models1', Model
        @propData 'models2', Model
        @propData 'models3', Model
        @end()

      view = new TestView($scope = $rootScope.$new(false, $rootScope), 'view') # view expected to take an empty set of data
      view.render = (render = jasmine.createSpy());
      $rootScope.$digest();
      expect(render.calls.count()).toEqual(0) # initial dirty is false

      view.dataUpdate() # takes set, and sets dirty to true that causes render to be called
      expect(dsDataService._dataCounter()).toBe(3)
      $rootScope.$digest();
      expect(view.dataStatus).toBe('nodata')

      dsDataService._set1.set 'status', 'update'
      dsDataService._set2.set 'status', 'ready'
      dsDataService._set3.set 'status', 'nodata'
      $rootScope.$digest();
      expect(view.dataStatus).toBe('nodata')

      dsDataService._set3.set 'status', 'ready'
      $rootScope.$digest();
      expect(view.dataStatus).toBe('update')

      dsDataService._set1.set 'status', 'ready'
      $rootScope.$digest();
      expect(view.dataStatus).toBe('ready')

      $scope.$destroy() # view expected to be released
      $rootScope.$digest();
      expect(view.$ds_ref).toBe(0)

      dsDataService._data.release owner
