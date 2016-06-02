
emptyFunction = require "emptyFunction"
isType = require "isType"
define = require "define"
Event = require "event"
Retry = require "retry"
Type = require "Type"
Void = require "Void"
Q = require "q"

type = Type "Loader", ->
  @load.apply this, arguments

type.optionTypes =
  load: Function
  retry: [ Retry.Kind, Void ]

type.optionDefaults =
  load: emptyFunction

type.createArguments (args) ->

  if isType args[0], Function
    args[0] = load: args[0]

  return args

type.defineProperties

  isLoading: get: ->
    @_loading isnt null

type.defineFrozenValues

  didLoad: -> Event()

  didAbort: -> Event()

  didFail: -> Event()

type.defineValues

  retry: (options) -> options.retry

  __load: (options) -> options.load

type.defineReactiveValues

  _loading: null

type.defineMethods

  load: ->

    return @_loading if @isLoading

    if @_retry?.isRetrying
      @_retry.reset()

    aborted = no
    onAbort = @didAbort.once =>
      aborted = yes

    args = arguments
    @_loading = Q.try =>
      @__load.apply this, args

    .always =>
      onAbort.stop()
      @_loading = null

    .then (result) =>
      return if aborted
      @__onLoad result

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
    @__onUnload()
    return

  __onLoad: emptyFunction.thatReturnsArgument

  __onUnload: emptyFunction

module.exports = type.build()
