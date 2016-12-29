module.exports = (ngModule = angular.module 'ui/tasks/rmsTaskAdd', []).name

ngModule.directive 'rmsTaskAdd', [
  '$rootScope',
  ($rootScope) ->

    link: ($scope, element) ->

      $scope.addTask = ->
        $rootScope.modal =
          type: 'task-edit'

      dragStart = (ev)-> # Note: If we use jQuery.on for this event, we don't have e.dataTransfer option
#        $rootScope.modal =
#          type: 'drag-start'
#          task: task = $scope.$eval attrs.rmsTask
#          scope: $scope
#        $rootScope.$digest()
        element.addClass 'drag-start'
        ev.dataTransfer.effectAllowed = 'move'
        ev.dataTransfer.setData 'new', true
        ev.dataTransfer.setDragImage element[0], 20, 20
        true # (ev)->

      dragEnd = (ev)->
        element.removeClass 'drag-start'
#        $rootScope.modal = {type: null}
#        $rootScope.$digest()
        true # (ev)->

      for el in $('*', element).addBack() # set enventListeners on li and it's children
        el.draggable = true
        el.addEventListener 'dragstart', dragStart
        el.addEventListener 'dragend', dragEnd

      return] # link:

