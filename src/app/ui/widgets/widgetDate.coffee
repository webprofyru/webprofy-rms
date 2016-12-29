module.exports = (ngModule = angular.module 'ui/widgets/widgetDate', []).name

# Localization is taken from http://trentrichardson.com/examples/timepicker/
# Note: For some reasons timepicker sources only has timepicker localization, but date localization is missing

$.datepicker.regional['ru'] = {
#  closeText: 'Закрыть',
#  prevText: '<Пред',
#  nextText: 'След>',
#  currentText: 'Сегодня',
#  monthNames: ['Январь','Февраль','Март','Апрель','Май','Июнь',
#               'Июль','Август','Сентябрь','Октябрь','Ноябрь','Декабрь'],
#  monthNamesShort: ['Янв','Фев','Мар','Апр','Май','Июн',
#                    'Июл','Авг','Сен','Окт','Ноя','Дек'],
#  dayNames: ['воскресенье','понедельник','вторник','среда','четверг','пятница','суббота'],
#  dayNamesShort: ['вск','пнд','втр','срд','чтв','птн','сбт'],
#  dayNamesMin: ['Вс','Пн','Вт','Ср','Чт','Пт','Сб'],
#  weekHeader: 'Не',
  dateFormat: 'dd.mm.yy',
  firstDay: 1,
#  isRTL: false,
#  showMonthAfterYear: false,
#  yearSuffix: ''
};
$.datepicker.setDefaults($.datepicker.regional['ru']);

$.timepicker.regional['ru'] = {
#  timeOnlyTitle: 'Выберите время',
#  timeText: 'Время',
#  hourText: 'Часы',
#  minuteText: 'Минуты',
#  secondText: 'Секунды',
#  millisecText: 'Миллисекунды',
#  timezoneText: 'Часовой пояс',
#  currentText: 'Сейчас',
#  closeText: 'Закрыть',
#  timeFormat: 'HH:mm',
#  amNames: ['AM', 'A'],
#  pmNames: ['PM', 'P'],
#  isRTL: false
};
$.timepicker.setDefaults($.timepicker.regional['ru']);

ngModule.directive 'widgetDate',
['$rootScope', '$timeout', (($rootScope, $timeout) ->
  restrict: 'EA'
  require: 'ngModel'
  link: (($scope, element, attrs, model) ->
    input = $('input', element)
    $timeout (->
      input.datepicker()
      input.change (->
        model.$setViewValue if (t = input.datetimepicker('getDate')) then moment(t.getTime()) else null
        $rootScope.$digest()
        return)
      (model.$render = (->
        input.datetimepicker 'setDate', if model.$viewValue then new Date(model.$viewValue.valueOf()) else null
        return))()
      return), 0
    return)
  )]
