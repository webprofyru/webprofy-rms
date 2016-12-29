module.exports = (ngModule = angular.module 'data/teamwork/TWPeople', [
  require '../../../dscommon/DSDataSource'
  require './DSDataTeamworkPaged'
]).name

assert = require('../../../dscommon/util').assert
error = require('../../../dscommon/util').error

Person = require '../../models/Person'

ngModule.factory 'TWPeople', ['DSDataTeamworkPaged', 'DSDataSource', '$rootScope', '$q', ((DSDataTeamworkPaged, DSDataSource, $rootScope, $q) ->

  return class TWPeople extends DSDataTeamworkPaged

    @begin 'TWPeople'

    @addPool()

    @propSet 'people', Person

    @ds_dstr.push (->
      @__unwatch2()
      return)

    init: ((dsDataService) ->
      @set 'request', "people.json"
      @__unwatch2 = DSDataSource.setLoadAndRefresh.call @, dsDataService
      @init = null
      return)

    startLoad: ->

      @peopleMap = {}

    importResponse: (json) ->

      cnt = 0

      for jsonPerson in json['people']

        ++cnt

        person = Person.pool.find @, "#{jsonPerson['id']}", @peopleMap

        person.set 'id', +jsonPerson['id']
        person.set 'name', "#{jsonPerson['last-name']} #{jsonPerson['first-name'].charAt(0).toUpperCase()}.".trim()
        person.set 'firstName', jsonPerson['first-name'].trim()
        person.set 'avatar', jsonPerson['avatar-url']
        person.set 'email', jsonPerson['email-address']
        person.set 'companyId', +jsonPerson['company-id']
        person.set 'currentUser', false

      cnt

    finalizeLoad: ->
      @get('peopleSet').merge @, @peopleMap
      delete @peopleMap
      return

    @end())]
