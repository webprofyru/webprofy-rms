assert = require('../../dscommon/util').assert
error = require('../../dscommon/util').error

time = require('../ui/time')

DSDocument = require('../../dscommon/DSDocument')

Project = require('./Project')
Person = require('./Person')
TaskList = require('./TaskList')
TaskTimeTracking = require('./TaskTimeTracking')
Tag = require './Tag'

DSTags = require('../../dscommon/DSTags')

Comments = require('./types/Comments')
TaskSplit = require('./types/TaskSplit')

module.exports = class Task extends DSDocument
  @begin 'Task'

  Comments.addPropType @
  TaskSplit.addPropType @
  DSTags.addPropType @

  @defaultTag = defaultTag = {name: '[default]', priority: 1000}

  @addPool true

  updateTaskPriority = (task, val) ->
    task.set 'plan', !!(val && val.get(Task.planTag))
    if val != null
      topPrior = 1000000
      topTag = null
      #for tagName, tag of val.map when (tagPriority = tag.get('priority')) < topPrior
      for tagName, tag of val.map
        if (tagPriority = tag.get('priority')) < topPrior
          topTag = tag
          topPrior = tagPriority
      task.__setCalcPriority topTag.priority
      task.__setCalcStyle topTag
    else
      task.__setCalcPriority defaultTag.priority
      task.__setCalcStyle defaultTag
    return

  processTagsEditable =
    __onChange: (task, propName, val, oldVal) ->
      switch propName
        when 'plan' # sync tags with prop 'plan' value
          tags = task.get 'tags'
          if tags
            tags = tags.clone @
            if val
              unless tags.get Task.planTag
                tags.set Task.planTag, (planTag = Tag.pool.find @, Task.planTag)
                planTag.release @
                task.set 'tags', tags
            else
              if tags.get Task.planTag
                tags.set Task.planTag, false
                task.set 'tags', if tags.empty() then null else tags
            tags.release @
          else if val
            (newTags = {})[Task.planTag] = planTag = Tag.pool.find @, Task.planTag
            tags = new DSTags @, newTags
            task.set 'tags', tags
            tags.release @
        when 'tags'
          updateTaskPriority task, val
      return

  processTagsOriginal =
    __onChange: (task, propName, val, oldVal) =>
      if propName == 'tags'
        updateTaskPriority task, val
      return

  @ds_ctor.push ->
    if @__proto__.constructor.ds_editable # work only for editable version
      if @hasOwnProperty '$ds_evt' then @$ds_evt.push processTagsEditable else @$ds_evt = [processTagsEditable]
    else
      if @hasOwnProperty '$ds_evt' then @$ds_evt.push processTagsOriginal else @$ds_evt = [processTagsOriginal]
    return

  @str = ((v) -> if v == null then '' else v.get('title'))

  @propNum 'id', init: 0
  @propDoc 'project', Project
  @propDoc 'taskList', TaskList
  @propStr 'title'
  (@propDuration 'estimate').str = ((v) ->
    hours = Math.floor v.asHours()
    minutes = v.minutes()
    res = if hours then "#{hours}h" else ''
    res += " #{minutes}m" if minutes
    res = '0' if !res
    return res)
  (@propMoment 'duedate').str = ((v) -> if v == null then '' else v.format 'DD.MM.YYYY')
  (@propMoment 'startDate').str = ((v) -> if v == null then '' else v.format 'DD.MM.YYYY')

  @propDoc 'creator', Person
  # TODO: No support for multiple persons
  @propDoc 'responsible', Person
  @propTaskRelativeSplit 'split'

  @propDSTags 'tags' # 'read:' option, is defined in dsChanges.init()
  @propBool 'completed'
  @propBool 'plan', write: null, read: null # TODO: Initial solution.  It's depricated by 'tags', but still in use

  @propStr 'description', str: (v) ->
    if !v || v.length == 0 then ''
    else if v.length <= 20 then v
    else "#{v.substr 0, 20}..."

  @propEnum 'status', ['new', '', 'deleted'], init: '', common: true

  @propComments 'comments'

  # Note: null - time tracking is not expected, (timeTracking.isReady == false) - time data is not loaded yet
  @propDoc 'timeTracking', TaskTimeTracking, write: null
  @propStr 'firstTimeEntryId', write: null

  @propBool 'isReady', write: null

  # calculated props
  @propNum 'priority', init: defaultTag.priority, calc: true
  @propObj 'style', init: (-> defaultTag), calc: true

  @propBool 'clipboard', init: false, common: true

  isOverdue: (-> (duedate = @get('duedate')) != null && duedate < time.today)

  timeWithinEstimate: (->
    return 0 if (estimate = @get('estimate')) == null
    return Math.min(100, Math.round(@get('timeTracking').get('totalMin') * 100 / estimate.asMinutes())))

  timeAboveEstimate: (->
    return 0 if (estimate = @get('estimate')) == null
    return if ((percent = Math.round(@get('timeTracking').get('totalMin') * 100 / estimate.asMinutes())) <= 100) then 0 else if percent > 200 then 100 else (percent - 100))

  timeReported: (->
    return '' if (estimate = @get('estimate')) == null
    return if ((percent = Math.round(@get('timeTracking').get('totalMin') * 100 / estimate.asMinutes())) > 200) then "#{percent} %" else '')

  grade: (->
    return '' if (estimate = @get('estimate')) == null
    return 'easy' if (estimate.asMinutes() < 60)
    return 'medium' if (estimate.asMinutes() >= 60 && estimate.asMinutes() < 240)
    return 'hard' if (estimate.asMinutes() >= 240 && estimate.asMinutes() < 480)
    return 'complex' if (estimate.asMinutes() >= 480))

  setVisible: ((isVisible) ->
    if isVisible
      if (@__visCount = (@__visCount || 0) + 1) == 1
        @get('timeTracking')?.setVisible true
    else if --@__visCount == 0
        @get('timeTracking')?.setVisible false
    return)

  @end()

  originalEditableInit = @Editable::init

  @Editable::init = ->
    originalEditableInit.apply @, arguments
    updateTaskPriority @, @get('tags')
    return
