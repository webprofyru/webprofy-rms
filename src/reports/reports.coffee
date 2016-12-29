FileSaver = require '../../static/libs/FileSaver.js/FileSaver'

serviceOwner = require('../dscommon/util').serviceOwner

PeriodTimeTracking = require './models/PeriodTimeTracking'

base64 = require '../utils/base64'

base62ToBlob = require '../utils/base62ToBlob'

module.exports = (ngModule = angular.module 'reports-app', [
  'ui.bootstrap'
  require './showSpinner'
  require './data/dsDataService'
  require './data/teamwork/TWPeriodTimeTracking'
]).name

defaultTask = "Без задачи"

fixStr = (str) ->

  if str == null

    str

  else

    str.replace(/"/g, '""')
    #.replace(/\\/g, "\\\\").replace(/[\n\t\r]/g,"")

projectReport = (workbook) ->

  styleSheet = workbook.getStyleSheet()

  fontBold = styleSheet.createFormat font: {bold: true}

  alightRight = styleSheet.createFormat font: {bold: true}, alignment: {horizontal: 'right'}

  rateFormat = styleSheet.createFormat format: '0'

  hoursFormat = styleSheet.createFormat format: '0.00'

  moneyFormat = styleSheet.createFormat format: '0.00'

  moneyFormatBold = styleSheet.createFormat format: '0.00', font: {bold: true}

  blue = styleSheet.createFormat font: {color: '002A00FF'}

  class ProjectReport

    constructor: ({@topRow = 0, data}) ->

      @rows = []

      @projectLine data.project
      @peopleLine data.people
      @ratesLine()
      @taskLine v.task, v.hours for v in data.tasks
      @totalHoursLine()
      @totalMoneyLine()
      @addRow()

    addRow: ->

      @rows.push @currRow = []

      return # addRow: ->

    skip: -> @currRow.push null; return

    rate: -> @currRow.push value: 0, metadata: {style: rateFormat.id}; return

    hours: (h) -> @currRow.push value: h, metadata: {style: hoursFormat.id}; return

    sumHoursVert: (rows) ->

      letter = String.fromCharCode(65 + @currRow.length)

      @currRow.push

        value: "SUM(#{letter}#{@topRow + 4}:#{letter}#{@topRow + @rows.length - 1})"

        metadata: {type: 'formula', style: hoursFormat.id}

      return

    sumHoursHoriz: (rows) ->

      fromLetter = String.fromCharCode(65 + @currRow.length + 1)

      toLetter = String.fromCharCode(65 + @currRow.length + @peopleCount)

      @currRow.push

        value: "SUM(#{fromLetter}#{@topRow + @rows.length}:#{toLetter}#{@topRow + @rows.length})"

        metadata: {type: 'formula', style: hoursFormat.id}

      return

    sumMoneyHoriz: (rows) ->

      fromLetter = String.fromCharCode(65 + @currRow.length + 1)

      toLetter = String.fromCharCode(65 + @currRow.length + @peopleCount)

      @currRow.push

        value: "SUM(#{fromLetter}#{@topRow + @rows.length}:#{toLetter}#{@topRow + @rows.length})"

        metadata: {type: 'formula', style: moneyFormatBold.id}

      return

    multHoursByRate: (rows) ->

      letter = String.fromCharCode(65 + @currRow.length)

      @currRow.push

        value: "#{letter}#{@topRow + 3}*#{letter}#{@topRow + @rows.length - 1}"

        metadata: {type: 'formula', style: moneyFormat.id}

      return

    totalByTaskTitle: -> @currRow.push value: 'Всего часов', metadata: {style: fontBold.id}; return

    ratesTitle: -> @currRow.push value: 'Стоимость часа (руб):', metadata: {style: alightRight.id}; return

    totalHoursTitle: -> @currRow.push value: 'Итого часов:', metadata: {style: alightRight.id}; return

    totalMoneyTitle: -> @currRow.push value: 'Сумма (руб):', metadata: {style: alightRight.id}; return

    person: (person) ->

      @currRow.push

        value: "HYPERLINK(\"http://teamwork.webprofy.ru/people/#{person.id}\", \"#{if person.missing then person.id else fixStr person.name}\")"

        metadata: {type: 'formula', style: blue.id}

      return

    project: (project) ->

      @currRow.push

        value: "HYPERLINK(\"http://teamwork.webprofy.ru/projects/#{project.id}/tasks\", \"#{fixStr project.name}\")"

        metadata: {type: 'formula', style: blue.id}

      return

    task: (task) ->

      @currRow.push (

        if task.id == null

          defaultTask

        else

          "#{task.name}")


          #value: "HYPERLINK(\"http://teamwork.webprofy.ru/tasks/#{task.id}\", \"#{fixStr task.name}\")"
          #value: "HYPERLINK(\"http://teamwork.webprofy.ru/tasks/#{task.id}\", \"#{task.id}\")"
          #value: "HYPERLINK(\"http://teamwork.webprofy.ru/tasks/#{task.id}\", \"#{fixStr ('' + task.id)}\")"

          #metadata: {type: 'formula', style: blue.id})

      return

    taskLink: (task) ->

      @currRow.push (

        if task.id == null

          ''

        else

          value: "HYPERLINK(\"http://teamwork.webprofy.ru/tasks/#{task.id}\", \"<<\")"

          metadata: {type: 'formula', style: blue.id})

      return


    projectLine: (project) -> @addRow(); @project project; return

    peopleLine: (people) ->

      @addRow(); @skip(); @skip(); @totalByTaskTitle()

      @person v for v in people

      @peopleCount = people.length

      return

    ratesLine: ->

      @addRow(); @skip(); @ratesTitle(); @skip()

      @rate() for i in [0...@peopleCount]

      return

    taskLine: (task, hours) ->

      @addRow(); @taskLink task; @task task; @sumHoursHoriz()
      #@addRow(); @skip(); @task task; @sumHoursHoriz()

      @hours h for h in hours

      return

    totalHoursLine: ->

      @addRow(); @skip(); @totalHoursTitle(); @sumHoursVert()

      @sumHoursVert() for i in [0...@peopleCount]

      return

    totalMoneyLine: ->

      @addRow(); @skip(); @totalMoneyTitle(); @sumMoneyHoriz()

      @multHoursByRate() for i in [0...@peopleCount]

      return

ngModule.directive 'reports', [
  'TWPeriodTimeTracking', 'dsDataService', 'config', '$http', '$rootScope',
  (TWPeriodTimeTracking, dsDataService, config, $http, $rootScope) ->
    restrict: 'A'
    scope: true
    link: ($scope, element, attrs) ->

      # Hack: TODO: uibDateParser within Angular UI wrongly use MONTH instead pf STANDALONEMONTH in 'month' mode.  So, I've quick fix it
      # $locale.DATETIME_FORMATS.MONTH = $locale.DATETIME_FORMATS.STANDALONEMONTH
      # ...but this didn't work - it fails to parse proper period string

      $scope.progressMessage = null
      $scope.period = moment().startOf('month').add(-1, 'month').toDate()
      $scope.selectPeriod = false

      $scope.generateReport = ->

        ProjectReport = projectReport wb = window.ExcelBuilder.createWorkbook()

#        pr1 = new ProjectReport data:
#          project: {id: 1, name: 'Проект 1'}
#          people: [
#            {id: 1, name: 'Петров'}
#            {id: 2, name: 'Сидоров'}
#          ]
#          tasks: [
#            {task: {id: 1, name: 'Задача 1'}, hours: [10.25, null]}
#            {task: {id: 2, name: 'Задача 2'}, hours: [null, 10.25]}
#            {task: {id: 3, name: 'Задача 3'}, hours: [6.7, 12]}
#          ]
#
#        pr2 = new ProjectReport topRow: pr1.rows.length, data:
#          project: {id: 1, name: 'Проект 2'}
#          people: [
#            {id: 1, name: 'Петров'}
#            {id: 2, name: 'Сидоров'}
#            {id: 3, name: 'Кто-то ещё'}
#          ]
#          tasks: [
#            {task: {id: 1, name: 'Задача 1'}, hours: [10.25, null, 7]}
#            {task: {id: 2, name: 'Задача 2'}, hours: [null, 10.25]}
#            {task: {id: 3, name: 'Задача 3'}, hours: [6.7, 12]}
#          ]
#
#        data = Array::concat.apply [], [pr1.rows, pr2.rows]

        #        # TODO: Collect all rows from all reports into one table
        #        # TODO: Find out max people list size
        #
        #        maxPeopleCount = 5
        #        columns = [{width: 4}, {width: 30}, {width: 20}]
        #        columns.push {width: 30} for i in [0...maxPeopleCount]
        #
        #        sheet = wb.createWorksheet name: 'Проверка'
        #        sheet.setData data
        #        sheet.setColumns columns
        #        wb.addWorksheet sheet
        #
        #        file = window.ExcelBuilder.createFile wb
        #
        #        blob = base62ToBlob file, 'application/vnd.ms-excel', 512
        #
        #        FileSaver.saveAs blob, "TestFile.xlsx"

        # return

        $scope.progressMessage = 'Идет загрузка данных...'
        from = moment $scope.period
        to = moment(from).add 1, 'month'
        periodTimeTrackingSet = dsDataService.findDataSet serviceOwner, type: PeriodTimeTracking, mode: 'original', from: from, to: to

        unwatch = periodTimeTrackingSet.watchStatus serviceOwner, (set, status) ->

          return unless status == 'ready'

          unwatch()

          projectsMap = {}

          reportData = []

          maxPeopleCount = 0

          # group by project.id (level 1) and by task.id (level 2)
          ((projectsMap[v.project.name] ||= {})[v.taskName] ||= []).push v for k, v of periodTimeTrackingSet.items

          # process projects in alphabet order of their names
          for projectName in (Object.keys projectsMap).sort()

            tasksMap = projectsMap[projectName]

            peopleMap = {}

            peopleMap[reports[0].person.name] = reports[0].person for k, reports of tasksMap

            # sorted list of people workd on the specific project in the period
            people = (peopleMap[personName] for personName in (Object.keys peopleMap).sort())

            maxPeopleCount = Math.max maxPeopleCount, people.length

            tasks = (for taskName, reports of tasksMap

              project = reports[0].project

              hours = (null for v in [0...people.length] by 1)

              for report in reports

                personIndex = people.indexOf report.person

                if hours[personIndex] == null

                  hours[personIndex] = report.totalMin / 60

                else

                  hours[personIndex] += report.totalMin / 60

              task: {id: reports[0].taskId, name: taskName}

              lastReport: reports[reports.length - 1].lastReport

              hours: hours) # tasks = (for taskName, reports of tasksMap

            # sort tasks by last report time
            .sort((left, right) ->

              if left.task.id == null then -1 # task with taksId should come first

              else if right.task.id == null then 1

              else left.lastReport.valueOf() - right.lastReport.valueOf())

#            console.info 'report data: ',
#
#              project: project
#
#              people: people
#
#              tasks: tasks

            reportData = reportData.concat (

              new ProjectReport topRow: reportData.length, data:

                project: project

                people: people

                tasks: tasks).rows

          $scope.progressMessage = 'Формируем MS Excel файл ...'
          $rootScope.$digest() unless $rootScope.$$phase

          $scope.$evalAsync ->

            columns = [{width: 4}, {width: 30}, {width: 20}]
            columns.push {width: 30} for i in [0...maxPeopleCount] by 1

            # reportData.length = 1000

            # console.info 'reportData: ', reportData

            sheet = wb.createWorksheet name: "По людям #{moment($scope.period).format('MM.YYYY')}"
            sheet.setData reportData
            sheet.setColumns columns
            wb.addWorksheet sheet

            file = window.ExcelBuilder.createFile wb

            blob = base62ToBlob file, 'application/vnd.ms-excel', 512

            FileSaver.saveAs blob, "Часы по людям по проектам за #{moment($scope.period).format('MM.YYYY')}.xlsx"

            periodTimeTrackingSet.release serviceOwner
            dsDataService.refresh() # to remove any cached data

            $scope.progressMessage = null
            $rootScope.$digest() unless $rootScope.$$phase

            return # wb.saveFile

          return # watchStatus

        return # $scope.generateReport

      return]
