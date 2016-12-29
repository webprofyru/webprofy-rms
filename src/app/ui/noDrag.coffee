assert = require('../../dscommon/util').assert
error = require('../../dscommon/util').error

module.exports = (ngModule  = angular.module  'ui/noDrag', []).name

ngModule.directive "noDrag", ->
  link: ($scope, element) ->
    el = element[0]
    el.addEventListener 'dragstart', (e) -> e.preventDefault(); false
    return
