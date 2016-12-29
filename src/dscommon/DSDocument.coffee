assert = require('./util').assert
error = require('./util').error
traceRefs = require('./util').traceRefs

DSObjectBase = require './DSObjectBase'
DSObject = require './DSObject'
DSSet = require './DSSet'

module.exports = class DSDocument extends DSObject
  @begin 'DSDocument'

  constructor: (referry, key) ->
    super referry, key
    if assert
      if @__proto__.constructor == DSDocument
        throw new Error 'Cannot instantiate DSDocument directly'

  @propPool = ((name, itemType) ->
    throw new Error "This property type is not supported in DSDocument"
    return)

  @propSet = ((name, itemType) ->
    throw new Error "This property type is not supported in DSDocument"
    return)

  @propList = ((name, itemType) ->
    throw new Error "This property type is not supported in DSDocument"
    return)

  @end()

  @end = (->
    DSObject.end.call @

    originalDocClass = @

    @Editable = class Editable extends originalDocClass
      @begin "#{originalDocClass.docType}.Editable"

      delete @::$ds_docType # takes docType from parent - no '.Editable' in the class name

      @ds_editable = true

      init = null
      for k, v of @__super__.__init when originalDocClass::__props[k.substr 1].calc
        (init || (init = {}))[k] = v
      @::__init = init # Editable object has not own props - it saves changes to @__changes and takes values of other props from serverDoc

      @ds_dstr.push (->
        if assert
          console.error 'Not an event listener' if !_.find @$ds_doc.$ds_evt, ((lst) => lst == @)
        _.remove @$ds_doc.$ds_evt, @
        @$ds_doc.release @
        if (change = @__change)
          for propName, propMap of change
            s.release @ if (s = propMap.s) instanceof DSObjectBase
            v.release @ if (v = propMap.v) instanceof DSObjectBase
        return)

      init: ((serverDoc, changesSet, changes) ->
        if assert
          error.invalidArg 'serverDoc' if !(serverDoc != null && serverDoc.__proto__.constructor == originalDocClass)
          error.invalidArg 'changesSet' if !(changesSet != null && changesSet instanceof DSSet)
          error.invalidArg 'changes' if !(arguments.length == 2 || typeof changes == 'object')
        (@$ds_doc = serverDoc).addRef @
        @$ds_chg = changesSet
        if (@__change = changes)
          notEmpty = false
          for propName, prop of changes
            if @__props[propName].equal serverDoc.get(propName), prop.v
              delete changes[propName]
            else
              notEmpty = true
          unless notEmpty
            delete @__change
          else
            if traceRefs
              list = []
              for propName, changePair of changes
                list.push changePair.v if changePair.v instanceof DSObjectBase
                list.push changePair.s if changePair.s instanceof DSObjectBase
              for item in list
                refs = item.$ds_referries
                if refs.length == 0
                  console.error "#{DSObjectBase.desc item}: Empty $ds_referries"
                else if (index = refs.lastIndexOf(owner)) < 0
                  console.error "#{DSObjectBase.desc @}: Referry not found: #{DSObjectBase.desc owner}"
                  debugger if totalReleaseVerb
                else
                  if totalReleaseVerb
                    console.info "#{++util.serviceOwner.msgCount}: transfer: #{DSObjectBase.desc item}, refs: #{@$ds_ref}, from: #{DSObjectBase.desc owner}, to: #{DSObjectBase.desc @}"
                    debugger if util.serviceOwner.msgCount == window.totalBreak
                  refs[index] = @
            @addRef @; changesSet.add @, @
        if !serverDoc.hasOwnProperty '$ds_evt' then serverDoc.$ds_evt = [@]
        else
          if assert
            console.error 'Already a listener' if _.find serverDoc.$ds_evt, ((lst) => lst == @)
          serverDoc.$ds_evt.push @
        @init = null
        return)

      __onChange: ((item, propName, value, oldVal) -> # react on server obj property change
        if (prop = item.__props[propName]).common
         if @$ds_evt
            lst.__onChange.call lst, @, propName, value, oldVal for lst in @$ds_evt by -1
        else if (change = @__change) && change.hasOwnProperty(propName)
          if prop.equal((val = (prop = change[propName]).v), value) # server val is the same as last edition of the propName
            s.release @ if (s = prop.s) instanceof DSObjectBase
            val.release @ if val instanceof DSObjectBase
            delete change[propName]
            empty = true
            for propName in change when propName != '__error' && propName != '__refreshView'
              empty = false
              break
            if empty
              delete @.__change
              @$ds_chg.remove @
        else if @$ds_evt
          lst.__onChange.call lst, @, propName, value, oldVal for lst in @$ds_evt by -1
        return)

      _clearChanges: -> # removes all changes made to the task, and cleaning up a hisotry of those changes
        if (change = @__change)
          for propName, prop of change # fix history
            if @$ds_evt
              lst.__onChange.call lst, @, propName, @$ds_doc[propName], prop.v for lst in @$ds_evt by -1
            s.release @ if (s = prop.s) instanceof DSObjectBase
            v.release @ if (v = prop.v) instanceof DSObjectBase
          delete @.__change
          @$ds_chg.remove @
        return # _clearChanges:

      props = Editable::__props = originalDocClass::__props # same props as on server version of document class
      @::get = ((propName) ->
        if assert
          error.invalidProp @, propName if !props.hasOwnProperty propName
        return @[propName])
      @::set = ((propName, value) ->
        if assert
          error.invalidProp @, propName if !props.hasOwnProperty propName
        return @[propName] = value)

      for k, prop of originalDocClass::__props when !prop.calc
        do (propName = prop.name, valid = prop.valid, equal = prop.equal) =>

          if prop.common
            Object.defineProperty @::, propName,
              get: -> @$ds_doc[propName]
              set: (value) ->
                if (oldVal = @$ds_doc[propName]) != value
                  @$ds_doc[propName] = value
                  @$ds_chg.$ds_hist.add @, propName, value, oldVal
                return
          else
            Object.defineProperty @::, propName,
              get: getValue = ->
                change = @__change
                return change[propName].v if change && change.hasOwnProperty(propName)
                @$ds_doc[propName]
              set: (value) ->
                if assert
                  error.invalidValue @, propName, v if typeof (value = valid(v = value)) == 'undefined'
                if !equal((oldVal = getValue.call(@)), value)
                  value.addRef @ if value instanceof DSObjectBase
                  if !(change = @__change) # it's first change for this document
                    change = @__change = {}
                    oldVal.addRef @ if oldVal instanceof DSObjectBase
                    change[propName] = {v: value, s: oldVal}
                    @addRef @; @$ds_chg.add @, @
                    @$ds_chg.$ds_hist.add @, propName, value, oldVal
                  else if equal((serverValue = @$ds_doc[propName]), value) # new value is equal to server value of this property
                    @$ds_chg.$ds_hist.add @, propName, value, (changePair = change[propName]).v
                    v.release @ if (v = changePair.v) instanceof DSObjectBase
                    s.release @ if (s = changePair.s) instanceof DSObjectBase
                    delete change[propName]
                    empty = true; (empty = false; break) for k of change when k != '__error' && k != '__refreshView'
                    if empty
                      if @$ds_evt # send change event before remove. This makes possible corrent exclude items from DSSet on change event
                        lst.__onChange.call lst, @, propName, value, oldVal for lst in @$ds_evt by -1
                      delete @.__change
                      @$ds_chg.remove @
                      return
                  else if (changePair = change[propName]) # this propery was already change, so we preserv inital serverValue
                    @$ds_chg.$ds_hist.add @, propName, value, changePair.v
                    v.release @ if (v = changePair.v) instanceof DSObjectBase
                    changePair.v = value
                  else # it's first change of this property, but not first change for this whole document
                    serverValue.addRef @ if serverValue instanceof DSObjectBase
                    change[propName] = {v: value, s: serverValue}
                    @$ds_chg.$ds_hist.add @, propName, value, oldVal
                  if @$ds_evt
                    lst.__onChange.call lst, @, propName, value, oldVal for lst in @$ds_evt by -1
                return

      DSObject.end.call @ # Note: We cannot simply call @end(), since this will cause a recursion of Editable definition

    return)
