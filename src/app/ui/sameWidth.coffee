assert = require('../../dscommon/util').assert
error = require('../../dscommon/util').error

module.exports = (ngModule  = angular.module  'ui/sameWidth', []).name

roundPeriod = 30 # ms
roundsToBeStable = 10 # times

ngModule.directive "sameWidth", ->
  scope: true
  controller: ['$scope', ($scope) ->
    @width = 0
    @update = []
    @scope = $scope
    return]
  link: ($scope, element, attrs, ctrl) ->
    if attrs.sameWidth
      $scope.$watch attrs.sameWidth, ->
        $scope.resizeInProgress()
    return

ngModule.directive "sameWidthSrc", ->
  require: '^sameWidth'
  scope: false
  link: ($scope, element, attr, ctrl) ->
    timer = null
    progress = false
    el = element[0]
    ctrl.scope.resizeInProgress = ->
      return if progress
      progress = true
      initWidth = el.clientWidth
      prevWidth = null
      roundsCount = roundsToBeStable
      changed = false
      timer = setInterval (->
        unless changed # it's not changed yet
          if initWidth != (prevWidth = el.clientWidth)
            changed = true
            f(prevWidth) for f in ctrl.update
        else
          v = prevWidth
          if v == (prevWidth = el.clientWidth) # it's stable
            if --roundsCount == 0
              clearInterval timer
              progress = false
          else # it's changing
            f(prevWidth) for f in ctrl.update
            roundsCount = roundsToBeStable
        return), roundPeriod
      return
    ctrl.scope.$on '$destroy', ->
      clearInterval timer
      return
    $scope.$evalAsync ->
      v = el.clientWidth
      f(v) for f in ctrl.update
    return

ngModule.directive "sameWidthDest", ->
  require: '^sameWidth'
  scope: false
  link: ($scope, element, attr, ctrl) ->
    ctrl.update.push (h) ->
      element.width h
      return
    return
