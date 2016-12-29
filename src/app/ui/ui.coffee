assert = require('../../dscommon/util').assert
error = require('../../dscommon/util').error
totalRelease = require('../../dscommon/util').totalRelease

DSObjectBase = require '../../dscommon/DSObjectBase' # To ensure that DSObjectBase definition window.totalRelease will be there
PersonDayStat = require '../models/PersonDayStat'

module.exports = (ngModule = angular.module 'ui/ui', [

  'ui.router'
  'ngSanitize'

  require './views/view1/View1'
  require './views/view2/View2'
  require './views/view3/View3'
  require './views/changes/ViewChanges'

  require './account/rmsAccount'

  require './widgets/widgetDate'
  require './widgets/widgetDuration'

  require './tasks/rmsTask'
  require './tasks/rmsTaskEdit'
  require './tasks/TaskSplitWeekView'
  require './tasks/rmsTaskInfo'
  require './tasks/rmsTaskAdd'

  require './tasks/addCommentAndSave'

  require './layout'
  require './filters'
  require './noDrag'
  require './sameHeight'
  require './sameWidth'

]).name

ngModule.config [
  '$urlRouterProvider', '$stateProvider', '$locationProvider', '$httpProvider'
  (($urlRouterProvider, $stateProvider, $locationProvider, $httpProvider) ->

    $stateProvider.state
      name: '/'
      url: '/'
      templateUrl: -> return './ui/main.html'
      controller: uiCtrl

    if totalRelease
      $stateProvider.state
        name: 'totalRelease'
        url: '/totalRelease'
        templat: "<div/>"

    return)]

if totalRelease
  ngModule.run [
    '$state', '$rootScope', (($state, $rootScope) ->
      superTotalRelease = window.totalRelease
      window.totalRelease = (->
        $state.go 'totalRelease' # releases all DSView objects
        $rootScope.$evalAsync (->
          superTotalRelease() # releases all DSObject based services
          # We should wait for some async release process - I don't know what is that
          setTimeout (-> console.info window.totalPool; return), 1000
          return)
        return)
    )]

uiCtrl = [
  '$rootScope', '$scope',
  (($rootScope, $scope) ->

    $scope.mode = 'edited'
    $scope.setMode = ((mode) ->
      $scope.mode = mode
      return)

    $scope.taskSummaryColor = ((dayStat)->
      if assert
        error.invalidArg 'dayStat' if !(dayStat instanceof PersonDayStat.DayStat)
      return if (timeLeft = dayStat.get('timeLeft').valueOf()) < 0 then 'red' # person is overloaded
      else if (timeLeft / dayStat.get('contract').valueOf()) <= 0.2 then 'green' # person is loaded more then 80%
      else 'light-yellow') # not loaded enough

    $scope.dayTaskWidth = ((dayStat)->
      if assert
        error.invalidArg 'dayStat' if !(dayStat instanceof PersonDayStat.DayStat)
      return if (timeLeft = dayStat.get('timeLeft').valueOf()) < 0 then 100 # 100% of available time is taken
      else Math.round((1 - timeLeft / dayStat.get('contract').valueOf()) * 100)) # percent of time taken from contracted hours

    $scope.taskViewExpand = ((index)-> $scope.period.people[index].tasks.expand = !$scope.period.people[index].tasks.expand; return)

    return)]
