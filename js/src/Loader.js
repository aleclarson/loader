var Event, Q, Retry, Type, Void, define, emptyFunction, isType, type;

emptyFunction = require("emptyFunction");

isType = require("isType");

define = require("define");

Event = require("event");

Retry = require("retry");

Type = require("Type");

Void = require("Void");

Q = require("q");

type = Type("Loader", function() {
  return this.load.apply(this, arguments);
});

type.optionTypes = {
  load: Function,
  retry: [Retry.Kind, Void]
};

type.optionDefaults = {
  load: emptyFunction
};

type.createArguments(function(args) {
  if (isType(args[0], Function)) {
    args[0] = {
      load: args[0]
    };
  }
  return args;
});

type.defineProperties({
  isLoading: {
    get: function() {
      return this._loading !== null;
    }
  }
});

type.defineFrozenValues({
  didLoad: function() {
    return Event();
  },
  didAbort: function() {
    return Event();
  },
  didFail: function() {
    return Event();
  }
});

type.defineValues({
  retry: function(options) {
    return options.retry;
  },
  __load: function(options) {
    return options.load;
  }
});

type.defineReactiveValues({
  _loading: null
});

type.defineMethods({
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
        return _this.__load.apply(_this, args);
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
        return _this.__onLoad(result);
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
    this.__onUnload();
  },
  __onLoad: emptyFunction.thatReturnsArgument,
  __onUnload: emptyFunction
});

module.exports = type.build();
