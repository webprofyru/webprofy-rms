module.exports = (ngModule = angular.module 'ui/tasks/rmsTaskInfo', []).name

assert = require('../../../dscommon/util').assert
error = require('../../../dscommon/util').error

DSObject = require('../../../dscommon/DSObject')

ngModule.directive 'rmsTaskInfo', ['$rootScope', '$window', (($rootScope, $window) ->
    restrict: 'A'
    scope: true
    link: (($scope, element, attrs) ->

      modal = $rootScope.modal

      if ($(window).height() > (modal.pos.top + 150))
        $scope.top = Math.ceil(modal.pos.top + 50)
      else
        $scope.top = Math.ceil(modal.pos.top - 100)

      if ($(window).width() - $('#sidebar').innerWidth() > modal.pos.left )
        $scope.left = Math.ceil(modal.pos.left + 95)
      else
        $scope.left = Math.ceil(modal.pos.left - 300)

      $scope.task = task = modal.task

      $scope.orderedTags =
        if (tags = task.get('tags'))
          (tag for tagName, tag of tags.map).sort (l, r) -> if (d = l.get('priority') - r.get('priority')) != 0 then d else l.get('name').localeCompare(r.get('name'))
        else []

      return)

    )]
