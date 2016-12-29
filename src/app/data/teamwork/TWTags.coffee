module.exports = (ngModule = angular.module 'data/teamwork/TWTags', [
  require '../../../dscommon/DSDataSource'
  require './DSDataTeamworkPaged'
]).name

assert = require('../../../dscommon/util').assert
error = require('../../../dscommon/util').error

Tag = require '../../models/Tag'

# Zork: Note: This code is not in use.  Instead we are loading tags right with loading tasks.  Might be later this code will be used in task tags editing.

ngModule.factory 'TWTags', ['DSDataTeamworkPaged', 'DSDataSource', '$rootScope', '$http', '$q', ((DSDataTeamworkPaged, DSDataSource, $rootScope, $http, $q) ->

  return class TWTags extends DSDataTeamworkPaged

    @begin 'TWTags'

    @addPool()

    @propObj 'cancel', init: null

    @propSet 'tags', Tag

    @ds_dstr.push (->
      @__unwatch()
      return)

    init: (dsDataService) ->
      @set 'request', "tags.json"
      @__unwatch = DSDataSource.setLoadAndRefresh.call @, dsDataService
      @init = null
      return

    startLoad: ->

      @tagsMap = {}

      onError = (error, isCancelled) =>
        if !isCancelled
# No tags.json - no problem
#          if error.hasOwnProperty('status') # it's $http response
#            toastr.error "Failed to load <i>data/tags.json</i>:<br/><br/> #{error.status} #{error.statusText}", null, positionClass: 'toast-top-center', newestOnTop: true, timeOut: -1
#          else # it's an exception
#            toastr.error "Invalid <i>data/tags.json</i>:<br/><br/> #{error.message}", null, positionClass: 'toast-top-center', newestOnTop: true, timeOut: -1
          @set 'cancel', null
        return []

      @tagsJson = $http.get "data/tags.json?t=#{new Date().getTime()}", timeout: @set('cancel', $q.defer()), transformResponse:  ((data, headers, status) -> JSONLint.parse data if status == 200)
      .then(((resp) => # ok
        unless resp.status == 200 # 0 means that request was canceled
          onError resp, resp.status == 0
        else
          @set 'cancel', null
          tags = resp.data
          unless Array.isArray(tags) # check data format
            console.error 'invalid tags.json'
            return []
          err = false
          for t, i in tags
            unless typeof t.name == 'string' && t.name.length >= 0
              err = true; console.error "invalid tags.json: invalid 'name'", t
            if t.hasOwnProperty('priority')
              unless typeof t.priority == 'number'
                err = true; console.error "invalid tags.json: invalid 'priority'", t
            else
              t.priority = i
            unless !t.hasOwnProperty('color') || typeof t.color == 'string' && t.color.length >= 0
              err = true; console.error "invalid tags.json: invalid 'color'", t
            unless !t.hasOwnProperty('border') || typeof t.border == 'string' && t.border.length >= 0
              err = true; console.error "invalid tags.json: invalid 'border'", t
          if err then [] else tags), onError)
      return

    importResponse: (json) ->

      cnt = 0

      for jsonTag in json['tags']

        ++cnt

        person = Tag.pool.find @, (tagName = jsonTag['name']), @tagsMap

        person.set 'id', parseInt jsonTag['id']
        person.set 'name', tagName
        person.set 'color', (tagColor = jsonTag['color'])
        person.set 'twColor', tagColor

      1 # to prevent from loading a next page

    finalizeLoad: ->

      @tagsJson.then (tags) => # apply data/tags.json info to teamwork tags
        @tagsJson = null
        for tag in tags when @tagsMap.hasOwnProperty(tag.name)
          tagDoc = @tagsMap[tag.name]
          tagDoc.set 'name', tag.name
          tagDoc.set 'priority', tag.priority if tag.hasOwnProperty('priority')
          tagDoc.set 'color', tag.color if tag.color
          tagDoc.set 'border', tag.border if tag.border
        @get('tagsSet').merge @, @tagsMap
        delete @tagsMap
        return

    @end())]
