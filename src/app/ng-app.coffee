# require '../../static/libs/digest-hud/digest-hud.js'

module.exports = (ngModule = angular.module 'app', [
  'ui.router' # static/libs/angular-ui/ui-router-0.2.13/angular-ui-router.js
  'ui.select' # static/libs/ui-select-0.10.0/select.js

  require './ui/ui'
  require './data/dsDataService'
  require './data/persistClipboard'
  require './svc/emails/emails'
  require './db'

  # 'digestHud'

]).name

ngModule.run ['config', '$rootScope', 'db', ((config, $rootScope, db)->
  $rootScope.Math = Math
  $rootScope.taskModal = {}
  $rootScope.startDateVal = null
  $rootScope.view3ActiveTab = null
  $rootScope.connnected = null
  return)]

ngModule.config [
  '$urlRouterProvider', '$stateProvider', '$locationProvider',
  (($urlRouterProvider, $stateProvider, $locationProvider) ->
#  '$urlRouterProvider', '$stateProvider', '$locationProvider', 'digestHudProvider',
#  (($urlRouterProvider, $stateProvider, $locationProvider, digestHudProvider) ->

    $locationProvider.html5Mode true
    $urlRouterProvider.otherwise '/'

#    digestHudProvider.enable()
#
#    # Optional configuration settings:
#    digestHudProvider.setHudPosition('top right') # setup hud position on the page: top right, bottom left, etc. corner
#    digestHudProvider.numTopWatches = 20 # number of items to display in detailed table
#    digestHudProvider.numDigestStats = 25 # number of most recent digests to use for min/med/max stats

    return)]
