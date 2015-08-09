(function() {
  var AsyncBinaryState, Promise,
    bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  Promise = require("bluebird");

  module.exports = AsyncBinaryState = (function() {
    function AsyncBinaryState(isOn1) {
      this.isOn = isOn1 != null ? isOn1 : false;
      this._set = bind(this._set, this);
      this.set = bind(this.set, this);
      this.setOff = bind(this.setOff, this);
      this.setOn = bind(this.setOn, this);
      this._targetState = this.isOn;
      this._promise = Promise.resolve();
    }

    AsyncBinaryState.prototype.setOn = function(handler) {
      return this.set(true, handler);
    };

    AsyncBinaryState.prototype.setOff = function(handler) {
      return this.set(false, handler);
    };

    AsyncBinaryState.prototype.set = function(isOn, handler) {
      var callback;
      callback = (function(_this) {
        return function() {
          return _this._set(isOn, handler);
        };
      })(this);
      return this._promise = this._promise.then(callback, callback);
    };

    AsyncBinaryState.prototype._set = function(isOn, handler) {
      var method;
      if (isOn === this._targetState) {
        return Promise.resolve();
      }
      this._targetState = isOn;
      if (handler != null) {
        method = Promise.method(function() {
          return handler();
        });
      } else {
        method = function() {
          return Promise.resolve();
        };
      }
      return method().tap((function(_this) {
        return function() {
          return _this.isOn = isOn;
        };
      })(this))["catch"]((function(_this) {
        return function(error) {
          _this._targetState = !isOn;
          throw error;
        };
      })(this));
    };

    return AsyncBinaryState;

  })();

}).call(this);

//# sourceMappingURL=AsyncBinaryState.js.map
