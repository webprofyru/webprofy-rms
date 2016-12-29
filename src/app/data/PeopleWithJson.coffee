module.exports = (ngModule = angular.module 'data/PeopleWithJson', [
]).name

assert = require('../../dscommon/util').assert
error = require('../../dscommon/util').error

DSSet = require '../../dscommon/DSSet'
DSTags = require '../../dscommon/DSTags'
DSData = require '../../dscommon/DSData'
DSDigest = require '../../dscommon/DSDigest'
DSDataServiceBase = require '../../dscommon/DSDataServiceBase'

Person = require '../models/Person'

ngModule.factory 'PeopleWithJson', [
  'DSDataSource', 'config', '$rootScope', '$http', '$q',
  ((DSDataSource, config, $rootScope, $http, $q) ->

    return class PeopleWithJson extends DSData

      @begin 'PeopleWithJson'

      @addPool()

      @propDoc 'teamworkPeople', DSSet
      @propObj 'cancel', init: null

      @propSet 'people', Person

      @ds_dstr.push (->
        cancel.resolve() if cancel = @get('cancel')
        @_unwatchA?()
        return)

      clear: (->
        DSData::clear.call @
        cancel.resolve() if cancel = @get('cancel')
        return)

      init: ((dsDataService) ->
        if assert
          error.invalidArg 'dsDataService' if !(dsDataService instanceof DSDataServiceBase)

        (teamworkPeople = @set 'teamworkPeople', dsDataService.findDataSet @, (_.assign {}, @params, {type: Person, source: true})).release @
        people = @get 'peopleSet'

        onError = ((error, isCancelled) =>
          if !isCancelled
            if error.hasOwnProperty('status') # it's $http response
              toastr.error "Failed to load <i>data/people.json</i>:<br/><br/> #{error.status} #{error.statusText}", null, positionClass: 'toast-top-center', newestOnTop: true, timeOut: -1
            else # it's an exception
              toastr.error "Invalid <i>data/people.json</i>:<br/><br/> #{error.message}", null, positionClass: 'toast-top-center', newestOnTop: true, timeOut: -1
            @set 'cancel', null
          @_endLoad false
          return)

        load = (=>
          return unless @_startLoad()
          cancel = @set('cancel', $q.defer())
          $http.get "data/people.json?t=#{new Date().getTime()}", timeout: cancel, transformResponse: ((data, headers, status) -> JSONLint.parse data if status == 200)
          .then(
            ((resp) => # ok
              if (resp.status == 200) # 0 means that request was canceled
                @set 'cancel', null
                DSDigest.block (=>
                  peopleRoles = $rootScope.peopleRoles = resp.data.roles # set roles to those who are in the list
                  if (selectedRole = $rootScope.selectedRole = config.get('selectedRole'))
                    for i in peopleRoles when i.role == selectedRole
                      $rootScope.selectedRole = i
                      break
                  filterManagers = $rootScope.filterManagers = [{name: 'All', $ds_key: null}]
                  for personInfo in resp.data.people
                    if teamworkPeople.items.hasOwnProperty(personKey = "#{personInfo.id}")
                      (twPerson = teamworkPeople.items[personKey]).set 'roles', dstags = new DSTags @, personInfo.role; dstags.release @
                      if personInfo.hasOwnProperty('projects') # Hack: It's an array of ides, so I do not treat it as a property - at the moment we don't have proper type
                        unless Array.isArray(personInfo.projects)
                          console.error "Person #{personInfo.name}: Invalid prop 'projects'"
                        else
                          try
                            twPerson.projects = projectMap = {}
                            projectMap[projectId] = true for projectId in personInfo.projects
                            filterManagers.push twPerson
                          catch
                            console.error "Person #{personInfo.name}: Invalid prop 'projects'"
                  if selectedManager = $rootScope.selectedManager = config.get('selectedManager')
                    for i in filterManagers when i.$ds_key == selectedManager
                      $rootScope.selectedManager = i
                      break
                  map = {} # copy whole list of people
                  for personKey, person of teamworkPeople.items
                    map[personKey] = person; person.addRef @
                  people.merge @, map
                  @_endLoad true
                  return)
              else onError(resp, resp.status == 0)
              return), onError)
          return)

        @_unwatchA = teamworkPeople.watchStatus @, ((source, status) =>
          if !(status == (prevStatus = @get('status')))
            switch status
              when 'ready' then DSDigest.block load
              when 'update' then DSDigest.block load
              when 'nodata' then @set 'status', 'nodata'
          return)

        @init = null
        return)

      @end())]