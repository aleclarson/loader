
emptyFunction = require "emptyFunction"
fromArgs = require "fromArgs"
getProto = require "getProto"
Promise = require "Promise"
isType = require "isType"
define = require "define"
Event = require "Event"
Retry = require "retry"
Type = require "Type"
Void = require "Void"

type = Type "Loader", ->
  @load.apply this, arguments

type.initArgs (args) ->
  if isType args[0], Function
    args[0] = load: args[0]
  return

type.defineOptions
  load: Function
  retry: Retry.Kind

type.defineValues

  retry: fromArgs "retry"

  __load: (options) ->
    return if getProto(this).__load isnt Loader::__load
    return options.load

type.defineReactiveValues

  _loading: null

type.defineEvents

  didAbort: null

  didFail:
    error: Error.Kind

type.defineGetters

  isLoading: -> @_loading isnt null

type.defineMethods

  load: ->

    return @_loading if @isLoading

    if @_retry?.isRetrying
      @_retry.reset()

    aborted = no
    onAbort = @didAbort 1, -> aborted = yes
    onAbort.start()

    args = arguments
    @_loading = Promise.try =>
      @__load.apply this, args

    .always =>
      onAbort.detach()
      @_loading = null

    .then (result) =>
      return if aborted
      @__onLoad result

    .fail (error) =>
      @_events.emit "didFail", [ error ]
      @_retry? => @load()
      throw error

  abort: ->
    @_retry and @_retry.reset()
    return unless @isLoading
    @_events.emit "didAbort"
    @_loading = null
    return

  unload: ->
    @abort()
    @__onUnload()
    return

type.defineHooks

  __load: null

  __onLoad: emptyFunction.thatReturnsArgument

  __onUnload: emptyFunction

module.exports = Loader = type.build()
