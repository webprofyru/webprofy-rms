assert = require('../../dscommon/util').assert
error = require('../../dscommon/util').error

module.exports = (ngModule  = angular.module  'ui/layout', []).name

area1MinHeight = 140
area1MinWidth = 730

area2MinHeight = 10

area3MinWidth = 10

windowMinWidth = 900
windowMinHeight = area1MinHeight + area3MinWidth

headerHeight = 44
actionsWidth = 440
actionsMinWidth = 440

ngModule.directive "uiLayout", [
  'config', '$window', '$rootScope',
  ((config, $window, $rootScope) ->
    $window = $($window)
    return {
      restrict: 'A'
      controller: ['$scope', (($scope) ->
        $scope.layout = @
        # TODO: Add config persistence
        @area1 = {}
        @area2 = {}
        @area3 = {}
        @width = $window.width()
        @area3.height = (@height = $window.height() - headerHeight)
        digest = (->
          $rootScope.$digest()
          $rootScope.$broadcast 'layout-update'
          return)
        (@setVResizer = ((v, noDigest) ->
          w = @area1.width = @area2.width = @vResizer = Math.min(Math.max(Math.round(v), area1MinWidth), @width - area3MinWidth)
          @area3.width = @width - w
          config.set 'vResizer', @area1.width / @width
          digest() if !noDigest
          return)).call @, @width * (config.get('vResizer') || 0.68), true
        (@setHResizer = ((v, noDigest) ->
          h = @area1.height = @hResizer = Math.min(Math.max(Math.round(v), area1MinHeight), @height - area2MinHeight)
          @area2.height = @height - h
          config.set 'hResizer', @area1.height / @height
          digest() if !noDigest
          return)).call @, @height * (config.get('hResizer') || 0.68), true
        @setSize = ((width, height, noDigest) ->
          height -= headerHeight
          change = false
          if (oldWidth = @width) != width
            change = true
            @setVResizer (@vResizer * ((@width = Math.max(width, windowMinWidth)) / oldWidth)), true
          if (oldHeight = @height) != height
            change = true
            @setHResizer (@hResizer * ((@height = Math.max(height, windowMinHeight)) / oldHeight)), true
            @area3.height = height
  #        console.info "area1: #{@area1.width}, #{@area1.height}, area2: #{@area2.width}, #{@area2.height}, area3: #{@area3.width}, #{@area3.height}; vResizer: #{@vResizer}, hResizer: #{@hResizer}"
          digest() if change && !noDigest
          return)
        return)]
      link: (($scope, element, attrs, uiLayout) ->
        $window.on 'resize', onResize = (->
          uiLayout.setSize $window.width(), $window.height()
          return)
        $scope.$on '$destroy', (->
          $window.off 'resize', onResize
          return)
        return)}
    return)]

ngModule.directive 'uiLayoutResizer', ['$document', (($document) ->
  return {
    restrict: 'A'
    require: '^uiLayout'
    link: (($scope, element, attrs, uiLayout) ->
      isHorizontal = attrs.uiLayoutResizer == 'horizontal'
      element.on 'mousedown', onMouseDown = ((event) ->
        event.preventDefault()
        $document.on 'mousemove', mousemove
        $document.on 'mouseup', mouseup
        return)
      mousemove =
        if isHorizontal then ((event) ->
          uiLayout.setHResizer event.pageY - headerHeight; return)
        else ((event) -> uiLayout.setVResizer event.pageX; return)
      mouseup = ((event)->
        $document.off 'mousemove', mousemove
        $document.off 'mouseup', mouseup
        return)
      $scope.$on '$destroy', (->
        $document.off 'mousedown', onMouseDown
        mouseup()
        return)
      return)}
  return)]

# Note: We cannot use DOM Element in Angular expresion, so we need a wrapper.
# Details from Angular - https://docs.angularjs.org/error/$parse/isecdom

class DOMWrapper
  constructor: ((DOMElement) ->
    @elem = DOMElement
    return)
  innerHeight: (-> @elem.innerHeight())

ngModule.directive 'uiLayoutContainer', ['$document', (($document) ->
  return {
    restrict: 'A'
    link: (($scope, element, attrs) ->
      $scope.uiContainer = new DOMWrapper(element)
      return)}
  return)]
