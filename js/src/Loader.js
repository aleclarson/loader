var Event, Loader, Promise, Retry, Type, Void, define, emptyFunction, getArgProp, getProto, isType, type;

emptyFunction = require("emptyFunction");

getArgProp = require("getArgProp");

getProto = require("getProto");

Promise = require("Promise");

isType = require("isType");

define = require("define");

Event = require("Event");

Retry = require("retry");

Type = require("Type");

Void = require("Void");

type = Type("Loader", function() {
  return this.load.apply(this, arguments);
});

type.defineOptions({
  load: {
    type: Function
  },
  retry: {
    type: Retry.Kind
  }
});

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
  retry: getArgProp("retry"),
  __load: function(options) {
    if (getProto(this).__load !== Loader.prototype.__load) {
      return;
    }
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
    onAbort = this.didAbort(1, function() {
      return aborted = true;
    });
    onAbort.start();
    args = arguments;
    return this._loading = Promise["try"]((function(_this) {
      return function() {
        return _this.__load.apply(_this, args);
      };
    })(this)).always((function(_this) {
      return function() {
        onAbort.detach();
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

type.mustOverride(["__load"]);

module.exports = Loader = type.build();

//# sourceMappingURL=../../map/src/Loader.map
