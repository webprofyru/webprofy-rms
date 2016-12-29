assert = require('../../dscommon/util').assert
error = require('../../dscommon/util').error

module.exports = (ngModule  = angular.module  'ui/sameHeight', []).name

roundPeriod = 10 # ms
roundsToBeStable = 10 # times

ngModule.directive "sameHeight", ->
  scope: true
  controller: ['$scope', ($scope) ->
    @height = 0
    @update = []
    @scope = $scope
    return]
  link: ($scope, element, attrs, ctrl) ->
    if attrs.sameHeight
      $scope.$watch attrs.sameHeight, ->
        $scope.resizeInProgress()
    return

ngModule.directive "sameHeightSrc", ->
  require: '^sameHeight'
  scope: false
  link: ($scope, element, attr, ctrl) ->
    timer = null
    progress = false
    ctrl.scope.resizeInProgress = ->
      return if progress
      progress = true
      initHeight = element.height()
      prevHeight = null
      roundsCount = roundsToBeStable
      changed = false
      timer = setInterval (->
        unless changed # it's not changed yet
          if initHeight != (prevHeight = element.height())
            changed = true
            f(prevHeight) for f in ctrl.update
        else
          v = prevHeight
          if v == (prevHeight = element.height()) # it's stable
            if --roundsCount == 0
              clearInterval timer
              progress = false
          else # it's changing
            f(prevHeight) for f in ctrl.update
            roundsCount = roundsToBeStable
        return), roundPeriod
      return
    ctrl.scope.$on '$destroy', ->
      clearInterval timer
      return
    $scope.$evalAsync ->
      v = element.height()
      f(v) for f in ctrl.update
    return

ngModule.directive "sameHeightDest", ->
  require: '^sameHeight'
  scope: false
  link: ($scope, element, attr, ctrl) ->
    ctrl.update.push (h) ->
      element.height h
      return
    return


