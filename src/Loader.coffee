
emptyFunction = require "emptyFunction"
getArgProp = require "getArgProp"
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

type.defineOptions

  load:
    type: Function

  retry:
    type: Retry.Kind

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

  retry: getArgProp "retry"

  __load: (options) ->
    return if getProto(this).__load isnt Loader::__load
    return options.load

type.defineReactiveValues

  _loading: null

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

type.mustOverride [
  "__load"
]

module.exports = Loader = type.build()
