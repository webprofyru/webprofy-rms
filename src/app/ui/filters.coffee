assert = require('../../dscommon/util').assert
error = require('../../dscommon/util').error

DSObject = require '../../dscommon/DSObject'

module.exports = (ngModule  = angular.module  'ui/filters', []).name

# TODO: Replace by use of moment locale
dayOfWeek = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']

ngModule.run ['$rootScope', (($rootScope) ->
  $rootScope.filter =

    calendarHeader: ((doc, prop) ->
      if assert
        if !(doc instanceof DSObject)
          error.invalidArg 'doc'
        if !((props = doc.__proto__.__props).hasOwnProperty prop)
          error.invalidArg 'prop'
        if !((type = props[prop].type) == 'moment')
          throw new Error "Expected property with type 'moment', but property '#{prop}' has type #{type}"
      if !date = doc.get(prop)
        throw new Error 'Non null date expected in the header'
      dtString = moment(date).format('YYYYMMDD')
      month = date.month() + 1
      if(month < 10) then month = '0' + month
      return "#{dayOfWeek[date.day()]} #{date.date()}/<small>#{month}</small>")

    shortDate: ((doc, prop) ->
      if assert
        if !(doc instanceof DSObject)
          error.invalidArg 'doc'
        if !((props = doc.__proto__.__props).hasOwnProperty prop)
          error.invalidArg 'prop'
        if !((type = props[prop].type) == 'moment')
          throw new Error "Expected property with type 'moment', but property '#{prop}' has type #{type}"
      date = doc.get(prop)
      return if !date then '' else date.format 'DD.MM')

    taskPeriod: ((doc, prop, time) -> # Hack: time parameter is quick solution to add spent time to estimate
      if assert
        if doc
          error.invalidArg 'doc' unless doc == null || doc instanceof DSObject
          error.invalidArg 'prop' unless prop == null || (props = doc.__proto__.__props).hasOwnProperty prop
          throw new Error "Expected property with type 'duration', but property '#{prop}' has type #{type}" if !((type = props[prop].type) == 'duration')
      res = ''

      if time
        if moment.isDuration time
          hours = Math.floor time.asHours()
          minutes = time.minutes()
        else
          hours = Math.floor (time = time.get('timeMin')) / 60
          minutes = time % 60
        if hours || minutes
          res += if hours then "#{hours}h " else ''
          res += "#{minutes}m" if minutes
        else res += '0'
      else if typeof time == null then res += '0'

      if doc && (duration = doc.get(prop))
        res += ' / ' if typeof time != 'undefined' && $rootScope.dataService.showTimeSpent
        hours = Math.floor duration.asHours()
        minutes = duration.minutes()
        res += if hours then "#{hours}h" else ''
        res += ' ' if hours and minutes
        res += "#{minutes}m" if minutes
        res += '0' if !res
      return res)

    taskPeriodLight: ((duration) ->
      if assert
        error.invalidArg 'duration' if !moment.isDuration(duration)
      return '' if !duration
      hours = Math.floor duration.asHours()
      minutes = duration.minutes()
      res = if hours then "#{hours}h" else ''
      res += " #{minutes}m" if minutes
      res = '0' if !res
      return res)

    periodDiff: ((diff) ->
      if assert
        error.invalidArg 'diff' if !(diff == null || moment.isDuration(diff))
      return '' if !diff || (val = diff.valueOf()) == null
      res = if val < 0 then (diff = moment.duration(-val); '- ') else '+ '
      hours = Math.floor diff.asHours()
      minutes = diff.minutes()
      res += "#{hours}h"
      res += " #{minutes}m" if minutes
      res = '0' if !res
      return res)

    timeLeft: ((diff) ->
      if assert
        error.invalidArg 'diff' if !(diff == null || moment.isDuration(diff))
      return '' if !diff || (val = diff.valueOf()) == null
      res = if val < 0 then (diff = moment.duration(-val); '- ') else ''
      hours = Math.floor diff.asHours()
      minutes = diff.minutes()
      res += "#{hours}h #{if minutes < 10 then '0' + minutes else minutes}m"
      return res)

    taskEditDueDate: ((date) ->
      if assert
        error.invalidArg 'date' if !(!date || moment.isMoment(date))
      return if !date then '' else date.format 'DD.MM.YYYY')

    splitDuration: ((duration, time) ->
      res = ''
      if time
        hours = Math.floor (time = time.get('timeMin')) / 60
        minutes = time % 60
        if hours || minutes
          res += if hours then "#{hours}h " else ''
#          res += ' ' if hours && minutes
          res += "#{minutes}m" if minutes
        else res += '0'
      else if typeof time == null then res += '0'
      if duration
        res += ' / ' if typeof time != 'undefined' && $rootScope.dataService.showTimeSpent
        hours = Math.floor duration.asHours()
        minutes = duration.minutes()
        res = if hours then "#{hours}h" else ''
        res += " #{minutes}m" if minutes
        res = '0' if !res
      return res)

  return)]
