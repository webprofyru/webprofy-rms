assert = require('../../dscommon/util').assert
serviceOwner = require('../../dscommon/util').serviceOwner

Task = require('../models/Task.coffee')

module.exports = (ngModule = angular.module 'data/persistClipboard', [
  require './dsDataService.coffee'
]).name

ngModule.factory 'clipboardTasks', [
  'localStorageService',
  (localStorageService) ->
    res = {}
    unless (v = localStorageService.get 'clipboardTasks') == null
      res[k] = true for k in v
    res]

ngModule.run [
  'dsDataService', 'localStorageService',
  (dsDataService, localStorageService) ->
    set = serviceOwner.add dsDataService.findDataSet serviceOwner, type: Task, mode: 'original', filter: 'clipboard'
    unwatch = serviceOwner.add set.watchStatus serviceOwner, (source, status) ->
      return unless status == 'ready'
      unwatch()
      (save = ->
        localStorageService.set 'clipboardTasks', (k for k of set.items)
        return)()
      serviceOwner.add set.watch serviceOwner,
        add: save
        remove: save
      return
    return]