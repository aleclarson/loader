
emptyFunction = require "emptyFunction"
getProto = require "getProto"
Promise = require "Promise"
isType = require "isType"
Event = require "Event"
Retry = require "Retry"
Type = require "Type"

type = Type "Loader"

type.inherits Function

type.initArgs (args) ->
  if isType args[0], Function
    args[0] = load: args[0]
  return

type.defineOptions
  load: Function
  retry: Retry.Kind

type.createInstance ->
  self = -> self.load.apply self, arguments

type.defineValues

  retry: (options) -> options.retry

  __load: (options) ->
    return if getProto(this).__load isnt Loader::__load
    return options.load

type.defineReactiveValues

  _loading: null

type.addMixin Event.Mixin,
  didAbort: null
  didFail: {error: Error.Kind}

type.defineGetters

  isLoading: -> @_loading isnt null

type.defineMethods

  load: ->

    return @_loading if @isLoading

    if @_retry?.isRetrying
      @_retry.reset()

    aborted = no
    onAbort = @once "didAbort", -> aborted = yes
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
      @emit "didFail", error
      @_retry? => @load()
      throw error

  abort: ->
    @_retry and @_retry.reset()
    return unless @isLoading
    @emit "didAbort"
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
