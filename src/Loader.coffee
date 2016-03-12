
{ isKind, Void } = require "type-utils"
{ async } = require "io"

emptyFunction = require "emptyFunction"
Immutable = require "immutable"
Factory = require "factory"
define = require "define"
Event = require "event"

module.exports = Factory "Loader",

  kind: Function

  initArguments: (options) ->
    options = { load: options } if isKind options, Function
    [ options ]

  optionTypes:
    load: [ Function, Void ]

  customValues:

    isLoading: get: ->
      @_loading?

  initFrozenValues: (options) ->

    didLoad: Event()

    didAbort: Event()

    didFail: Event()

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

    aborted = no
    onAbort = @didAbort.once =>
      aborted = yes

    args = arguments
    @_loading = async.try =>
      @_load.apply this, args

    .always =>
      onAbort.stop()
      @_loading = null

    .then (result) =>
      return if aborted
      @_onLoad result

    .fail (error) =>
      @didFail.emit error
      throw error

  abort: ->
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

  _load: emptyFunction

  _onLoad: emptyFunction.thatReturnsArgument

  _onUnload: emptyFunction
