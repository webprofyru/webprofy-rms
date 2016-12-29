module.exports = (ngModule = angular.module 'data/dsDataService', [
  require '../../dscommon/DSDataSource'
  require '../../app/config'
  require '../../dscommon/DSDataSource'
  require '../../app/data/teamwork/TWPeople'
  require '../../app/data/PeopleWithJson'
  require './teamwork/TWProjects'
  require './teamwork/TWPeriodTimeTracking'
]).name

assert = require('../../dscommon/util').assert
serviceOwner = require('../../dscommon/util').serviceOwner
error = require('../../dscommon/util').error

base64 = require '../../utils/base64'

DSDataServiceBase = require '../../dscommon/DSDataServiceBase'

Person = require '../../app/models/Person'
Project = require '../../app/models/Project'
PeriodTimeTracking = require '../models/PeriodTimeTracking'

ngModule.run ['dsDataService', '$rootScope', (dsDataService, $rootScope) ->
  $rootScope.dataService = dsDataService
  return]

ngModule.factory 'dsDataService', [
 'TWPeriodTimeTracking', 'PeopleWithJson', 'TWPeople', 'TWProjects', 'DSDataSource', 'config', '$http', '$rootScope', '$q',
 (TWPeriodTimeTracking, PeopleWithJson, TWPeople, TWProjects, DSDataSource, config, $http, $rootScope, $q) ->

    class DSDataService extends DSDataServiceBase
      @begin 'DSDataService'

      @propDoc 'dataSource', DSDataSource

      @propSet 'peopleSet', Person
      @propSet 'projectsSet', Project
      @propSet 'periodTimeTrackingSet', PeriodTimeTracking

      @ds_dstr.push (->
        @__unwatch2()
        return)

      constructor: ->
        DSDataServiceBase.apply @, arguments
        (@set 'dataSource', new DSDataSource(@, 'dataSource')).release @

        cancel = null
        @__unwatch2 = $rootScope.$watch (-> [config.get('teamwork'), config.get('token')]), (([teamwork, token]) =>

          if !(teamwork && token)
            @get('dataSource').setConnection(null, null)
          else
            (cancel.resolve(); cancel = null) if cancel

            onError = ((error, isCancelled) =>
              if !isCancelled
                console.error 'error: ', error
                cancel = null
              @get('dataSource').setConnection(null, null)
              return)

            # make sure that we have working teamwork url and token
            $http.get "#{teamwork}authenticate.json",
              timeout: (cancel = $q.defer()).promise
              headers: {Authorization: "Basic #{base64.encode(token)}"}
            .then ((resp) =>
              if (resp.status == 200) # 0 means that request was canceled
                cancel = null
                config.set 'currentUserId', resp.data['account']['userId']
                @get('dataSource').setConnection(teamwork, token)
              else onError(resp, resp.status == 0)
              return), onError

            return), true # $rootScope.$watch
        return # constructor:

      refresh: ->
        @get('dataSource').refresh()
        return

      findDataSet: (owner, params) ->
        DSDataServiceBase::findDataSet.call @, owner, params

        switch params.type.docType
          when 'Person'
            if params.source # it's internal call from PeopleWithJson load
              delete params.source
              (data = TWPeople.pool.find(@, params)).init? @
              (set = data.get('peopleSet')).addRef owner; data.release @
            else
              (data = PeopleWithJson.pool.find(@, params)).init? @
              (set = data.get('peopleSet')).addRef owner; data.release @
            return set
          when 'Project'
            (data = TWProjects.pool.find(@, params)).init? @
            (set = data.get('projectsSet')).addRef owner; data.release @
            return set
          when 'PeriodTimeTracking'
            (data = TWPeriodTimeTracking.pool.find(@, params)).init? @
            (set = data.get('timeTrackingSet')).addRef owner; data.release @
            return set
        return

      requestSources: (owner, params, sources) ->
        DSDataServiceBase::requestSources.call @, owner, params, sources
        throw new Error 'requestSources() is not implemented for reports.  It\'s not expected that DSView will be used'
        return

      @end()

    return serviceOwner.add(new DSDataService serviceOwner, 'dataService')]
