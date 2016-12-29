base64 = require '../../../utils/base64'

Task = require '../../models/Task'
Person = require '../../models/Person'

module.exports = (ngModule = angular.module 'svc-emails', [
  require '../../data/dsDataService']
).name

ngModule.config [
  '$urlRouterProvider', '$stateProvider', '$locationProvider', '$httpProvider'
  (($urlRouterProvider, $stateProvider, $locationProvider, $httpProvider) ->

    $stateProvider.state
      name: 'emails'
      url: '/emails'
      templateUrl: -> return './svc/emails/main.html'
      controller: ctrl

    return)]

ctrl =
  ['$scope', '$http', '$sce', 'config', 'dsDataService',
  (($scope, $http, $sce, config, dsDataService) ->

    $scope.dateCheck = ''

    $scope.isDateCheckOk = (->
      return false unless /\d{1,2}\.\d{2}\.\d{4}/.test $scope.dateCheck
      moment($scope.dateCheck, 'DD.MM.YYYY').startOf('day').valueOf() == moment().startOf('day').valueOf())

    $scope.state = 'notStarted' # 'inProgress', 'completed'

    $scope.data = null

    $scope.formatDuration = formatDuration = ((duration) ->
      hours = Math.floor duration.asHours()
      minutes = duration.minutes()
      res = if hours then "#{hours} ч." else ''
      if minutes
        res += ' ' if res
        res += "#{minutes} мин."
      return res)

    # https://thawing-chamber-8269.herokuapp.com - is https://github.com/Rob--W/cors-anywhere app, running under account alexey@zorkaltsev.com

    $scope.prepare = (->

      peopleSet = dsDataService.findDataSet @, {type: Person, mode: 'original'}
      tasksSet = dsDataService.findDataSet @, {
        type: Task
        mode: 'original'
        filter: 'assigned'
        startDate: startDate = moment().startOf('week')
        endDate: endDate = moment(startDate).add(6, 'days')}

      formatHours = ((project) ->
        planHours = formatDuration(project.planHours)
        optHours = formatDuration(project.optHours)
        res = planHours
        if optHours
          res += ' + ' if res
          res += "<span style='background-color:rgb(255,153,0)'>#{optHours}</span>"
        project.hours = $sce.trustAsHtml res
        return project)

      compute = (->
        console.info 'compute started...'

        $scope.emails = emails = []

        for person in (people = _.sortBy (_.map peopleSet.items), ((person) -> person.get('name')))
          continue if person.get('roles') == null # it's got to be a client
          projects = {}
          for taskKey, task of tasksSet.items when task.get('responsible') == person && task.get('estimate') != null
            continue if task.get('taskList').get('id') == 462667 # skip vocations tasks
            if !(projectState = projects[projectKey = (project = task.get('project')).$ds_key])
              projectState = projects[projectKey] =
                id: project.get('id')
                name: project.get('name')
                planHours: moment.duration()
                optHours: moment.duration()
                manager: ''

            hours = if task.get('title').toLowerCase().indexOf('бронь') != -1 || task.get('taskList').get('name').toLowerCase().indexOf('бронь') != -1
              projectState.optHours
            else projectState.planHours

            if (split = task.get('split'))
              duedate = task.get('duedate')
              d = moment(startDate)
              while d <= endDate
                hours.add dur if (dur = split.get duedate, d) != null
                d.add 1, 'day'
            else hours.add task.get('estimate')

          totalHours = moment.duration()
          if (projects = _.map projects, ((project) -> totalHours.add(project.planHours); totalHours.add(project.optHouras); formatHours(project))).length > 0
            projects = _.sortBy projects, ((project) -> project.name)
            emails.push {
              person,
              toName: person.get('firstName')
              startDate: startDate.format('DD.MM')
              endDate: endDate.format('DD.MM.YYYY')
              totalHours: formatDuration(totalHours)
              projects
              status: 'notSent'}

        console.info 'compute finished: ', emails
        return)

      watch = (->
        if peopleSet.status == 'ready' && tasksSet.status == 'ready'
          compute()
          unwatch1()
          unwatch2()
        return)

      unwatch1 = peopleSet.watchStatus @, watch
      unwatch2 = tasksSet.watchStatus @, watch

      peopleSet.release @
      tasksSet.release @

      return)

    sendEmail = ((index) ->
      email = $scope.emails[index]
      html = template({email})
      personRoles = email.person.get 'roles'
      to = email.person.get 'email'
      cc = 'managers@webprofy.ru'
      if personRoles.get('Designer') || personRoles.get('Jr. Designer')
        cc += ', a.shevtsov@webprofy.ru, a.kolesnikov@webprofy.ru'
      if personRoles.get('Markuper')
        cc += ', n.skinteev@webprofy.ru, s.yastrebov@webprofy.ru'

      console.info 'to: ', to
      console.info 'cc: ', cc

      $http({
        method: 'POST'
        url: 'https://thawing-chamber-8269.herokuapp.com/https://api.mailgun.net/v3/webprofy.ru/messages'
#        url: 'http://cors-anywhere.herokuapp.com/https://api.mailgun.net/v3/webprofy.ru/messages'
        data: $.param({
          to: email.person.get 'email'
          cc: cc
          from: 'Татьяна Верхотурова <t.verkhoturova@webprofy.ru>'
          subject: email.title
          html: html
        })
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded'
        # username : password - account alexey@zorkaltsev.com @ https://mailgun.com
          'Authorization': "Basic #{base64.encode('api:key-3ccadef54df260c8a2903da328ebb165')}"}})
      .then(
        ((ok) ->
          console.info 'ok: ',  ok
          email.status = 'sent'
          if index + 1 == $scope.emails.length
            $scope.state = 'completed'
          else sendEmail index + 1
          return),
        ((error) ->
          console.error 'error: ',  error
          $scope.state = 'error'
          return))

      return)

    $scope.sendOut = (->
      $scope.state = 'inProgress'
      sendEmail 0
      return)
    return)]
