module.exports = (ngModule = angular.module 'ui/views/changes/ViewChanges', [
  require '../../../data/dsChanges'
  require('../../../../dscommon/DSView')
]).name

assert = require('../../../../dscommon/util').assert

DSObject = require('../../../../dscommon/DSObject')
DSDigest = require('../../../../dscommon/DSDigest')

Task = require('../../../models/Task')
Person = require('../../../models/Person')
Change = require('./models/Change')

ngModule.run ['$rootScope', (($rootScope) ->
  $rootScope.showChanges = (->
    $rootScope.modal = if $rootScope.modal.type != 'changes' then {type: 'changes'} else {type: null}
    return)
  return)]

ngModule.controller 'ViewChanges', ['$scope', 'ViewChanges', 'dsChanges', '$rootScope', (($scope, ViewChanges, dsChanges, $rootScope) ->
  $scope.view = new ViewChanges $scope, 'viewChanges'
  $scope.save = (-> dsChanges.save().then((allTasksSaved) -> if allTasksSaved then $rootScope.modal = {type: null}; return); return)
  $scope.reset = (-> dsChanges.reset(); $rootScope.modal = {type: null}; return)
  return)]

ngModule.directive 'viewChangesFix', [
  (() ->
    restrict: 'A'
    link: (($scope, element, attrs) ->
      header = $('.main-table.header', element)
      data = $('.main-table.data', element)
      header.width data.width()
      return))]

ngModule.factory 'ViewChanges', ['DSView', 'dsChanges', '$log', ((DSView, dsChanges, $log) ->

  return class ViewChange extends DSView
    @begin 'ViewChange'

    @propData 'tasks', Task, {mode: 'changes'}

    @propPool 'poolChanges', Change
    @propList 'changes', Change

    @propNum 'renderVer', 0

    constructor: (($scope, key) ->
      DSView.call @, $scope, key
      @dataUpdate {}
      return)

    @ds_dstr.push (->
      for taskKey, task of @get('data').get('tasksSet').items
        delete task.__change.__refreshView
      return)

    render: (->
      if !((tasksStatus = @get('data').get('tasksStatus')) == 'ready' || tasksStatus == 'update')
        @get('changesList').merge @, []
        return

      poolChanges = @get 'poolChanges'
      changes = []
      props = (tasksSet = @get('data').get('tasksSet')).type::__props
      isDark = false
      refreshView = (=>
        @__dirty++ # force render(), since changes is not DSDocument, so it does not produce change events
        return)
      for taskKey, task of tasksSet.items
        isDark = !isDark
        task.__change.__refreshView = refreshView
        remove = do (task) -> ->
          dsChanges.removeChanges task
          refreshView()
          return

        taskChanges = []
        for propName, propChange of task.__change when propName != '__error' && propName != '__refreshView' && propName != 'clipboard'
          prop = props[propName]
          taskChanges.push(change = poolChanges.find @, "#{task.$ds_key}.#{propName}")
          change.set 'isDark', isDark
          change.set 'index', prop.index
          change.set 'prop', propName
          change.set 'value',
            if (v = propChange.v) == null then ' -' else prop.str(propChange.v)
          change.set 'conflict',
            if prop.equal((conflictValue = task.$ds_doc.get(propName)), propChange.s) then null
            else if conflictValue == null then ' -' else prop.str(conflictValue)

        taskChanges.sort (l, r) -> l.get('index') - r.get('index')
        taskChanges[0].set 'doc', task
        taskChanges[0].remove = remove

        Array::push.apply changes, taskChanges

        if task.__change.__error
          changes.push(change = poolChanges.find @, "#{task.$ds_key}.__error")
          change.set 'isDark', isDark
          change.set 'error', task.__change.__error

      @get('changesList').merge @, changes

      @set 'renderVer', (@get('renderVer') + 1)

      return)

    @end())]
