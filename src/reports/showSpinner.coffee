module.exports = (ngModule = angular.module 'showSpinner', []).name

spinnerOpts =
  lines: 13
  length: 1
  radius: 8
  color: '#000'
  opacity: 0.2

ngModule.directive 'showSpinner', [->
  restrict: 'A'
  link: ($scope, element, attrs) ->
    spinner = new Spinner(spinnerOpts).spin()
    element[0].appendChild spinner.el
    $scope.$on '$destroy', (->
      spinner.stop()
      return)
    return]
