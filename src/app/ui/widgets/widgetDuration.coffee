module.exports = (ngModule = angular.module 'ui/widgets/widgetDuration', []).name

msInHours = 60 * 60 * 1000
msInMinute = 60 * 1000

ngModule.directive 'widgetDuration',
['$rootScope', '$timeout',
(($rootScope, $timeout) ->
  restrict: 'EA'
  require: 'ngModel'
  link: (($scope, element, attrs, model) ->
    inputs = $('input', element)
    inputHours = $(inputs[0])
    inputMinutes = $(inputs[1])
    (model.$render = (->
      if (val = model.$viewValue)
        hours = Math.floor(val.valueOf() / msInHours) # Note; moment.duration.hours() is limited by 24hours
        minutes = Math.floor(val.valueOf() % msInHours / msInMinute)
        inputHours.val hours
        inputMinutes.val if minutes < 10 then '0' + minutes else minutes
      else
        inputHours.val ''
        inputMinutes.val ''
      return))()
    change = (->
      h = parseInt inputHours.val()
      m = parseInt inputMinutes.val()
      d = moment.duration(0)
      d.add h, 'hours' if !isNaN h
      d.add m, 'minutes' if !isNaN m
      model.$setViewValue if d.valueOf() == 0 then null else d
      $rootScope.$digest()
      return)
    inputHours.on 'input', change
    inputMinutes.on 'input', change
    return)
  )]
