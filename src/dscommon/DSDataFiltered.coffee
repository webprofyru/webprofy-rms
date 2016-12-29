assert = require('./util').assert
error = require('./util').error

DSObject = require './DSObject'
DSData = require './DSData'
DSDigest = require './DSDigest'
DSSet = require './DSSet'

classes = {} # Generic class implementations

module.exports = ((itemType) ->
  if assert
    error.invalidArg 'itemType' if !(DSObject.isAssignableFrom(itemType))

  # Note: During testing same named classes might change for every test, so we need to check items.type
  return if classes.hasOwnProperty(itemType.docType) && (clazz = classes[itemType.docType]).itemType == itemType then clazz
  else classes[itemType.docType] =
    class DSDataFiltered extends DSData
      @begin "DSDataFiltered<#{itemType.docType}>"

      @propDoc 'original', DSSet

      @propSet 'items', @itemType = itemType

      @ds_dstr.push (->
        @_unwatchA?()
        @_unwatch1?()
        return)

      clear: (->
        DSData::clear.call @
        @_unwatch1?(); delete @_unwatch1
        return)

      # TODO: Later, give edit rights based on actual user rights regarding a project
      @$u = $u = {}
      for k of itemType.__super__.__props
        $u[k] = true

      init: ((original, filter) ->

        if assert
          error.invalidArg 'original' if !(original instanceof DSSet)
          error.invalidArg 'filter' if !(typeof filter == 'function')
          throw new Error "'itemType' and 'original' must have same DSObject type" if !(itemType == original.type)

        @set 'original', original

        itemsSet = @get 'itemsSet'
        items = itemsSet.items
        originalItems = original.items

        load = (=>

          @_startLoad() # result is not checked intentionally, so we could set 'load' state while source object is in 'load' state

          @_unwatch1?(); @_unwatch1 = null

          for itemKey, item of originalItems
            if filter(item)
              item.addRef @; itemsSet.add @, item

          renderItem = ((itemKey) =>
            if items.hasOwnProperty itemKey
              itemsSet.remove item if !filter(item = originalItems[itemKey])
            else if filter(item = originalItems[itemKey])
              item.addRef @; itemsSet.add @, item
            return)

          @_unwatch1 = original.watch @,
            add: ((item) =>
              DSDigest.render @$ds_key, item.$ds_key, renderItem
              return)
            change: ((item) =>
              DSDigest.render @$ds_key, item.$ds_key, renderItem
              return)
            remove: ((item) =>
              itemsSet.remove item
              DSDigest.forget @$ds_key, item.$ds_key
              return)

          @_endLoad true

          return)

        @_unwatchA = original.watchStatus @, ((source, status) =>
          inUpdate = false
          if !((newStatus = original.get('status')) == (prevStatus = @get('status')))
            switch newStatus
              when 'ready'
                if inUpdate
                  inUpdate = false
                  @_endLoad true
                else
                  DSDigest.block load # it's only once, since 'update' is not assigned to state
              when 'load'
                @_startLoad()
              when 'update'
                if @_startLoad()
                  inUpdate = true
              when 'nodata'
                if inUpdate
                  inUpdate = false
                  @_endLoad false
                else
                  @set 'status', 'nodata'
          return)

        @init = null
        return)

      @end())
