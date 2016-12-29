assert = require('./util').assert
error = require('./util').error

DSDocument = require './DSDocument'
DSData = require './DSData'
DSDigest = require './DSDigest'
DSSet = require './DSSet'

classes = {} # Generic class implementations

module.exports = ((itemType) ->
  if assert
    error.invalidArg 'itemType' if !(itemType != null && itemType.ds_editable)

  # Note: During testing same named classes might change for every test, so we need to check items.type
  return if classes.hasOwnProperty(itemType.docType) && (clazz = classes[itemType.docType]).itemType == itemType then clazz
  else classes[itemType.name] =
    class DSDataEditable extends DSData
      @begin "DSDataEditable<#{itemType.docType}>"

      @propDoc 'original', DSSet
      @propDoc 'changes', DSSet

      @propSet 'items', @itemType = itemType

      @ds_dstr.push (->
        @_unwatchA?()
        @_unwatchB?()
        @_unwatch1?()
        @_unwatch2?()
        return)

      clear: (->
        DSData::clear.call @
        @_unwatch1?(); delete @_unwatch1
        @_unwatch2?(); delete @_unwatch2
        return)

      # TODO: Later, give edit rights based on actual user rights regarding a project
      @$u = $u = {}
      for k of itemType.__super__.__props
        $u[k] = true

      init: ((original, changes, filter) ->

        if assert
          error.invalidArg 'changes' if !(changes instanceof DSSet)
          error.invalidArg 'original' if !(original instanceof DSSet)
          error.invalidArg 'filter' if !(typeof filter == 'function' || typeof filter == 'undefined')
          throw new Error "'original' expected to have non DSDocument.Editable items" if !(!original.type.ds_editable)
          throw new Error "'itemType' and 'changes' must have same DSDocument.Editable type" if !(itemType == changes.type)
          throw new Error "'original' and 'changes' must base on same DSDocument type" if !(original.type.Editable == changes.type)
          throw new Error "'changes' must be set instantiated as a field of DSChanges object" if !(changes.hasOwnProperty '$ds_pool')

        @set 'original', original
        @set 'changes', changes

        itemsSet = @get('itemsSet')
        items = itemsSet.items
        editablePool = changes.$ds_pool
        originalItems = original.items
        changesItems = changes.items

        load = (=>

          @_startLoad() # result is not checked intentionally, so we could set 'load' state while source object is in 'load' state

          @_unwatch1?(); @_unwatch1 = null
          @_unwatch2?(); @_unwatch2 = null

          getEdtItem = ((srcItem) =>
            if assert
              throw new Error 'Missing editable item' if !editablePool.items.hasOwnProperty(srcItem.$ds_key)
            return editablePool.items[srcItem.$ds_key])

          findEdtItem = ((srcItem) =>
            if (edtItem = editablePool.find(@, srcItem.$ds_key)).init
              edtItem.init(srcItem, changes)
              edtItem.$u = $u
            return edtItem)

          if filter
            _.forEach originalItems, ((srcItem) =>
              if !changesItems.hasOwnProperty(key = srcItem.$ds_key)
                itemsSet.add @, findEdtItem(srcItem)
                return)
            _.forEach changesItems, ((edtItem) =>
              if filter.call @, edtItem
                itemsSet.add @, (edtItem.addRef @)
                return)
            renderItem = ((itemKey) =>
              if assert
                throw new Error 'Missing edtItem' if !changesItems.hasOwnProperty(itemKey)
              filterItem changesItems[itemKey]
              return)
            filterItem = ((edtItem) =>
              if filter.call @, edtItem
                if !items.hasOwnProperty(edtItem.$ds_key)
                  itemsSet.add @, (edtItem.addRef @)
              else if items.hasOwnProperty(edtItem.$ds_key)
                itemsSet.remove edtItem
              return)
            filterItemIfChanged = ((srcItem) =>
              return false if !changesItems.hasOwnProperty(srcItem.$ds_key)
              filterItem getEdtItem srcItem
              return true)
            @_unwatch1 = original.watch @,
              add: ((srcItem) =>
                if !filterItemIfChanged(srcItem)
                  itemsSet.add @, findEdtItem srcItem
                  return)
              remove: ((srcItem) =>
                if !filterItemIfChanged(srcItem)
                  itemsSet.remove getEdtItem srcItem
                  DSDigest.forget @$ds_key, srcItem.$ds_key
                  return)
            @_unwatch2 = changes.watch @,
              add: ((edtItem) =>
                DSDigest.render @$ds_key, edtItem.$ds_key, renderItem
                return)
              change: ((edtItem) =>
                DSDigest.render @$ds_key, edtItem.$ds_key, renderItem
                return)
              remove: ((edtItem) =>
                filterItem.call @, edtItem
                DSDigest.forget @$ds_key, edtItem.$ds_key
                return)
          else # if no filter then simply duplicates original set
            _.forEach originalItems, ((srcItem) => itemsSet.add @, findEdtItem(srcItem); return)
            @_unwatch1 = original.watch @,
              add: ((srcItem) =>
                itemsSet.add @, findEdtItem srcItem; return)
              remove: ((srcItem) =>
                itemsSet.remove getEdtItem srcItem; return)

          @_endLoad true

          return)

        sets = [original, changes]
        updateStatus = ((source, status) =>
          inUpdate = false
          if !((newStatus = DSDocument.integratedStatus(sets)) == (prevStatus = @get('status')))
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

        @_unwatchA = original.watchStatus @, updateStatus
        @_unwatchB = changes.watchStatus @, updateStatus

        @init = null
        return)

      @end())
