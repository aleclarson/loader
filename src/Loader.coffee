
{ Void } = require "type-utils"

emptyFunction = require "emptyFunction"
Immutable = require "immutable"
Factory = require "factory"
define = require "define"
Event = require "event"
Retry = require "retry"
Q = require "q"

module.exports = Factory "Loader",

  kind: Function

  initArguments: (options) ->
    options = { load: options } if options instanceof Function
    [ options ]

  optionTypes:
    retry: [ Retry.Kind, Void ]

  customValues:

    isLoading: get: ->
      @_loading?

  initFrozenValues: (options) ->

    didLoad: Event()

    didAbort: Event()

    didFail: Event()

    _retry: options.retry

  initReactiveValues: ->

    _loading: null

  init: (options) ->

    if options.load?
      define this, "_load",
        value: options.load
        enumerable: no

  func: ->
    @load.apply this, arguments

  load: ->

    return @_loading if @isLoading

    if @_retry?.isRetrying
      @_retry.reset()

    aborted = no
    onAbort = @didAbort.once =>
      aborted = yes

    args = arguments
    @_loading = Q.try =>
      @_load.apply this, args

    .always =>
      onAbort.stop()
      @_loading = null

    .then (result) =>
      return if aborted
      @_onLoad result

    .fail (error) =>
      @didFail.emit error
      @_retry? => @load()
      throw error

  abort: ->
    @_retry?.reset()
    return unless @isLoading
    @didAbort.emit()
    @_loading = null
    return

  unload: ->
    @abort()
    @_onUnload()
    return

#
# Overrideable
#

  _load: -> Q()

  _onLoad: emptyFunction.thatReturnsArgument

  _onUnload: emptyFunction
