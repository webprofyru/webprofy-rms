module.exports = util =
  assert: true
  traceData: false
  traceWatch: false # add to watch listener 'owner' value
  traceView: false
  traceRefs: false
  totalRelease: false # Use windows.totalRelease() to real all object, and check window.totalPool to see if there any object left unreleased
  totalReleaseVerb: false
  modeReleaseDataOnReload: true
  serviceOwner: new class ServiceOwner
    constructor: (->
      @name = 'serviceOwner'
      @services = []
      @poolCleaners = []
      return)
    start: (->
      @services = []
      @poolCleaners = []
      return)
    stop: (->
      s.release @ for s in @services
      c() for c in @poolCleaners if @poolCleaners
      return)
    add: ((svc) ->
      @services.push svc
      return svc)
    remove: ((svc) ->
      _.remove @services, svc
      return)
    clearPool: ((poolCleaner) ->
      @poolCleaners.push poolCleaner)
  validate:
    required: ((value) ->
      return if typeof value != 'undefined' && value != null then value else undefined)
    trimString: ((value) ->
      return if typeof value != 'string' then null else if (value = value.trim()).length == 0 then null else value)
  error:
    invalidArg: ((name) ->
      throw new Error "Invalid '#{name}' parameter"
      return)
    notDSObjectClass: ((clazz) ->
      throw new Error "Not a DSObject class"
      return)
    invalidProp: ((object, propName) ->
      throw new Error "Obj '#{object}': Prop '#{propName}': Invalid property"
      return)
    invalidListValue: ((index, invalidValue) ->
      throw new Error "Invalid value '#{invalidValue}' at position #{index}"
      return)
    duplicatedProperty: ((type, propName) ->
      throw new Error "Class '#{type.docType}': Prop '#{propName}': Duplicated property name"
      return)
    propIsReadOnly: ((type, propName) ->
      throw new Error "Class '#{type.docType}': Prop '#{propName}': Property is read-only"
      return)
    invalidValue: ((object, propName, invalidValue) ->
      throw new Error "Obj '#{object}': Prop '#{propName}': Invalid value '#{invalidValue}'"
      return)
    invalidMapElementType: ((invalidValue) ->
      throw new Error "Invalid element type '#{invalidValue}'"
      return)
    invalidPropMapElementType: ((object, propName, invalidValue) ->
      throw new Error "Obj '#{object}': Prop '#{propName}': Invalid value '#{invalidValue}'"
      return)
