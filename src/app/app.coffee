toastr.options =
  closeButton: false
  debug: false
  newestOnTop: false
  progressBar: false
  positionClass: 'toast-bottom-right'
  preventDuplicates: false
  onclick: null
  showDuration: 300
  hideDuration: 1000
  timeOut: 5000
  extendedTimeOut: 1000
  showEasing: 'swing'
  hideEasing: 'linear'
  showMethod: 'fadeIn'
  hideMethod: 'fadeOut'

window.JSONLint = require '../../static/libs/jsonlint/jsonlint.js'

require './ng-app'

#window.sourceBreak = 51
#window.viewBreak = 8

moment.locale 'ru' # switch to 'ru'
