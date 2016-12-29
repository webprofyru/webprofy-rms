module.exports = (ngModule = angular.module 'data/teamwork/TWProjects', [
  require '../../../dscommon/DSDataSource'
  require '../../../app/data/teamwork/DSDataTeamworkPaged'
]).name

assert = require('../../../dscommon/util').assert
error = require('../../../dscommon/util').error

Project = require '../../../app/models/Project'

ngModule.factory 'TWProjects', ['DSDataTeamworkPaged', 'DSDataSource', '$rootScope', '$q', ((DSDataTeamworkPaged, DSDataSource, $rootScope, $q) ->

  return class TWProjects extends DSDataTeamworkPaged

    @begin 'TWProjects'

    @addPool()

    @propSet 'projects', Project

    @ds_dstr.push (->
      @__unwatch2()
      return)

    init: ((dsDataService) ->
      @set 'request', "projects.json?status=ALL"
      @__unwatch2 = DSDataSource.setLoadAndRefresh.call @, dsDataService
      @init = null
      @projectsMap = {}
      return)

    startLoad: ->
      @projectsMap = {}
      return

    importResponse: (json) ->

      cnt = 0

      for jsonProject in json['projects']

        ++cnt

        project = Project.pool.find @, "#{jsonProject['id']}", @projectsMap

        project.set 'id', parseInt jsonProject['id']
        project.set 'name', jsonProject['name']
        project.set 'status', jsonProject['status']

      cnt

    finalizeLoad: ->
      @get('projectsSet').merge @, @projectsMap
      return

    @end())]
