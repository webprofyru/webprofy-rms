assert = require('../dscommon/util').assert

serviceOwner = require('../dscommon/util').serviceOwner

DSObject = require '../dscommon/DSObject'

module.exports = (ngModule = angular.module 'db', [
]).name

ngModule.factory 'db',
  ['$q',
  (($q) ->

    dbDeferred = null

    class DB extends DSObject
      @begin 'DB'

      @propConst 'name', 'RMS'
      @propConst 'ver', 4

      logQuota: (->
#        if webkitTemporaryStorage = navigator.webkitTemporaryStorage
#          webkitTemporaryStorage.queryUsageAndQuota(webkitTemporaryStorage.TEMPORARY,
#            ((used, remaining) ->
#              console.info "webkitTemporaryStorage: used quota: #{used}, remaining quota: #{remaining}"
#              return),
#            ((error) ->
#              console.info "webkitTemporaryStorage: ", error
#              return))
#        else
#          console.info "webkitTemporaryStorage: Missing window.webkitTemporaryStorage"
        return)

      openDB: (->
        if !window.indexedDB
          console.warn "IndexedDB.openDB: Missing window.indexedDB, so there will be no local time tracking info"
          dbDeferred.reject()
          return

        if !dbDeferred
          dbDeferred = $q.defer()
          request = window.indexedDB.open @get('name'), @get('ver')
          request.onsuccess = ((event) ->
            console.info "IndexedDB.openDB: Success"
            dbDeferred.resolve(event.target.result)
            return)
          request.onerror = ((event) ->
            console.warn "IndexedDB.openDB: Error", event
            dbDeferred.reject()
            return)
          request.onupgradeneeded = ((event) ->
            console.info "IndexedDB.openDB: Upgrade", event
            db = event.target.result
            try
              db.deleteObjectStore 'timetracking'
            catch e # nothing
            db.createObjectStore 'timetracking', keyPath: 'page'
            dbDeferred.resolve(db)
            return)

        return dbDeferred.promise)

      @end()

    return serviceOwner.add(new DB serviceOwner, 'db'))]

