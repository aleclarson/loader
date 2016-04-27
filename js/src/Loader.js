var Event, Factory, Immutable, Q, Retry, Void, define, emptyFunction;

Void = require("type-utils").Void;

emptyFunction = require("emptyFunction");

Immutable = require("immutable");

Factory = require("factory");

define = require("define");

Event = require("event");

Retry = require("retry");

Q = require("q");

module.exports = Factory("Loader", {
  kind: Function,
  initArguments: function(options) {
    if (options instanceof Function) {
      options = {
        load: options
      };
    }
    return [options];
  },
  optionTypes: {
    retry: [Retry.Kind, Void]
  },
  customValues: {
    isLoading: {
      get: function() {
        return this._loading != null;
      }
    }
  },
  initFrozenValues: function(options) {
    return {
      didLoad: Event(),
      didAbort: Event(),
      didFail: Event(),
      _retry: options.retry
    };
  },
  initReactiveValues: function() {
    return {
      _loading: null
    };
  },
  init: function(options) {
    if (options.load != null) {
      return define(this, "_load", {
        value: options.load,
        enumerable: false
      });
    }
  },
  func: function() {
    return this.load.apply(this, arguments);
  },
  load: function() {
    var aborted, args, onAbort, ref;
    if (this.isLoading) {
      return this._loading;
    }
    if ((ref = this._retry) != null ? ref.isRetrying : void 0) {
      this._retry.reset();
    }
    aborted = false;
    onAbort = this.didAbort.once((function(_this) {
      return function() {
        return aborted = true;
      };
    })(this));
    args = arguments;
    return this._loading = Q["try"]((function(_this) {
      return function() {
        return _this._load.apply(_this, args);
      };
    })(this)).always((function(_this) {
      return function() {
        onAbort.stop();
        return _this._loading = null;
      };
    })(this)).then((function(_this) {
      return function(result) {
        if (aborted) {
          return;
        }
        return _this._onLoad(result);
      };
    })(this)).fail((function(_this) {
      return function(error) {
        _this.didFail.emit(error);
        if (typeof _this._retry === "function") {
          _this._retry(function() {
            return _this.load();
          });
        }
        throw error;
      };
    })(this));
  },
  abort: function() {
    var ref;
    if ((ref = this._retry) != null) {
      ref.reset();
    }
    if (!this.isLoading) {
      return;
    }
    this.didAbort.emit();
    this._loading = null;
  },
  unload: function() {
    this.abort();
    this._onUnload();
  },
  _load: function() {
    return Q();
  },
  _onLoad: emptyFunction.thatReturnsArgument,
  _onUnload: emptyFunction
});

//# sourceMappingURL=../../map/src/Loader.map
