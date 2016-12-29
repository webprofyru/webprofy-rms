DSObject = require '../../src/app/dscommon/DSObject'
DSPool = require '../../src/app/dscommon/DSPool'
DSSet = require '../../src/app/dscommon/DSSet'
DSData = require '../../src/app/dscommon/DSData'

describe '210 View', ->

  # TODO: Test integrated state
  # TODO: Test dataUpdate method - no set change, with set change
  # TODO: Multiple set update with one is editable another is not
  # TODO: Skip render if prop does not affect render result

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
      @propNum 'num', 0
      @end()

    class ModelData extends DSData
      @begin 'TestData'
      @noCache()
      @propSet 'items', Model
      @end()

#    window.module require '../../src/app/data/dsDataService', (->
    angular.mock.module require '../../src/app/dscommon/DSView'
    angular.mock.module (($provide) ->
      $provide.factory 'dsDataService', (() ->
        data = new ModelData owner, 'data', {}
        dataCounter = 0
        return {
          _dataCounter: (-> dataCounter)
          _data: data
          _set: set = data.get 'itemsSet'
          _load: (->
            map = {}
            (Model.pool.find owner, '1', map).set 'text', 'element1'
            (Model.pool.find owner, '2', map).set 'text', 'element2'
            set.merge owner, map
            set.set 'status', 'ready'
            return)
          _change1: (-> # add new element
            newMap = _.clone set.items
            v.addRef owner for k, v of newMap
            (Model.pool.find owner, '3', newMap).set 'text', 'element3'
            set.merge owner, newMap
            return)
          _change2: (-> # remove element
            newMap = _.clone set.items
            delete newMap['2']
            v.addRef owner for k, v of newMap
            set.merge owner, newMap
            return)
          _change3: (-> # change element
            _.clone set.items['1'].set 'text', 'element1bis'
            return)
          _change4: (-> # change element
            _.clone set.items['1'].set 'num', 1
            return)
          requestSources: ((owner, params, sources) ->
            sources.models.newSet = set; set.addRef owner
            dataCounter += 1
            return)})
      return)

    inject (DSView, dsDataService, $rootScope, $httpBackend) ->

      $httpBackend.expectGET('data/people.json').respond '{}'

      class TestView extends DSView
        @begin 'TestView'
        @propData 'models', Model, {watch: ['text']}
        @end()

      view = new TestView($scope = $rootScope.$new(false, $rootScope), 'view') # view expected to take an empty set of data
      view.render = (render = jasmine.createSpy());
      $rootScope.$digest();
      expect(render.calls.count()).toEqual(0) # initial dirty is false

      view.dataUpdate() # takes set, and sets dirty to true that causes render to be called
      $rootScope.$digest();
      expect(view.data.get 'models').toBe(dsDataService._set.items)
      expect(view.dataStatus).toBe('nodata')
      expect(render.calls.count()).toEqual(1) # one first-time call with no data state

      dsDataService._load(); $rootScope.$digest();
      expect(render.calls.count()).toEqual(2) # +1 cause data sets were changed
      expect(view.dataStatus).toBe('ready')

      dsDataService._change1(); $rootScope.$digest();
      expect(render.calls.count()).toEqual(3) # +1 cause data sets were changed

      dsDataService._change2(); $rootScope.$digest();
      expect(render.calls.count()).toEqual(4) # +1 cause data sets were changed

      dsDataService._change3(); $rootScope.$digest();
      expect(render.calls.count()).toEqual(5) # +1 cause data sets were changed

      dsDataService._change4(); $rootScope.$digest();
      expect(render.calls.count()).toEqual(5) # +0 cause data property 'num' is not in the list of watching props

      $scope.$destroy() # view expected to be released
      expect(view.$ds_ref).toBe(0)

      dsDataService._data.release owner
