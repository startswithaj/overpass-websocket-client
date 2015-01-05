(function() {
  var AsyncBinaryState, bluebird,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  bluebird = require("bluebird");

  module.exports = AsyncBinaryState = (function() {
    function AsyncBinaryState(isOn) {
      this.isOn = isOn != null ? isOn : false;
      this._set = __bind(this._set, this);
      this.set = __bind(this.set, this);
      this.setOff = __bind(this.setOff, this);
      this.setOn = __bind(this.setOn, this);
      this._promise = bluebird.resolve();
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
      var promise;
      if (isOn === this.isOn) {
        return bluebird.resolve();
      }
      this.isOn = isOn;
      promise = bluebird.resolve(typeof handler === "function" ? handler() : void 0);
      promise["catch"]((function(_this) {
        return function() {
          return _this.isOn = !_this.isOn;
        };
      })(this));
      return promise;
    };

    return AsyncBinaryState;

  })();

}).call(this);

//# sourceMappingURL=AsyncBinaryState.js.map