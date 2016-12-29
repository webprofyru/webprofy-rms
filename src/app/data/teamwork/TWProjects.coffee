module.exports = (ngModule = angular.module 'data/teamwork/TWProjects', [
  require '../../../dscommon/DSDataSource'
  require './DSDataTeamworkPaged'
]).name

assert = require('../../../dscommon/util').assert
error = require('../../../dscommon/util').error

Project = require '../../models/Project'

ngModule.factory 'TWProjects', ['DSDataTeamworkPaged', 'DSDataSource', '$rootScope', '$q', ((DSDataTeamworkPaged, DSDataSource, $rootScope, $q) ->

  return class TWProjects extends DSDataTeamworkPaged

    @begin 'TWProjects'

    @addPool()

    @propSet 'projects', Project

    @ds_dstr.push (->
      @__unwatch2()
      return)

    init: ((dsDataService) ->
      @set 'request', "projects.json?status=ACTIVE"
      @__unwatch2 = DSDataSource.setLoadAndRefresh.call @, dsDataService
      @init = null
      return)

    startLoad: ->

      @projectsMap = {}

    importResponse: (json) ->

      cnt = 0

      for jsonProject in json['projects']

        ++cnt

        project = Project.pool.find @, "#{jsonProject['id']}", @projectsMap

        project.set 'id', parseInt jsonProject['id']
        project.set 'name', jsonProject['name']

      cnt

    finalizeLoad: ->
      @get('projectsSet').merge @, @projectsMap
      delete @projectsMap
      return

    @end())]
