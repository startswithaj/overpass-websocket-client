(function() {
  var AsyncBinaryState, EventEmitter, Promise, Subscription, TimeoutError, ref, regexEscape,
    bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    hasProp = {}.hasOwnProperty;

  regexEscape = require("escape-string-regexp");

  EventEmitter = require("events").EventEmitter;

  ref = require("bluebird"), Promise = ref.Promise, TimeoutError = ref.TimeoutError;

  AsyncBinaryState = require("../AsyncBinaryState");

  module.exports = Subscription = (function(superClass) {
    extend(Subscription, superClass);

    function Subscription(connection, topic, id, timeout1) {
      var atom, atoms;
      this.connection = connection;
      this.topic = topic;
      this.id = id;
      this.timeout = timeout1 != null ? timeout1 : 3;
      this._removeListeners = bind(this._removeListeners, this);
      this._disconnect = bind(this._disconnect, this);
      this._publish = bind(this._publish, this);
      this._subscribed = bind(this._subscribed, this);
      this._state = new AsyncBinaryState();
      atoms = (function() {
        var i, len, ref1, results;
        ref1 = this.topic.split(".");
        results = [];
        for (i = 0, len = ref1.length; i < len; i++) {
          atom = ref1[i];
          switch (atom) {
            case "*":
              results.push("(.+)");
              break;
            case "?":
              results.push("([^.]+)");
              break;
            default:
              results.push(regexEscape(atom));
          }
        }
        return results;
      }).call(this);
      this._pattern = new RegExp("^" + (atoms.join(regexEscape("."))) + "$");
    }

    Subscription.prototype.enable = function() {
      return this._state.setOn((function(_this) {
        return function() {
          var promise, timeout;
          promise = new Promise(function(resolve) {
            return _this._resolve = resolve;
          });
          _this.connection.on("message.pubsub.subscribed", _this._subscribed);
          _this.connection.on("message.pubsub.publish", _this._publish);
          _this.connection.on("disconnect", _this._disconnect);
          _this.connection.send({
            type: "pubsub.subscribe",
            id: _this.id,
            topic: _this.topic
          });
          timeout = Math.round(_this.timeout * 1000);
          return promise.timeout(timeout, "Subscription request timed out.")["catch"](TimeoutError, function(error) {
            _this._removeListeners();
            throw error;
          });
        };
      })(this));
    };

    Subscription.prototype.disable = function() {
      return this._state.setOff((function(_this) {
        return function() {
          _this.connection.send({
            type: "pubsub.unsubscribe",
            id: _this.id
          });
          return _this._removeListeners();
        };
      })(this));
    };

    Subscription.prototype._subscribed = function(message) {
      if (message.id === this.id) {
        return this._resolve();
      }
    };

    Subscription.prototype._publish = function(message) {
      if (this._pattern.test(message.topic)) {
        return this.emit("message", message.topic, message.payload);
      }
    };

    Subscription.prototype._disconnect = function() {
      return this._state.setOff(this._removeListeners);
    };

    Subscription.prototype._removeListeners = function() {
      this.connection.removeListener("message.pubsub.subscribed", this._subscribed);
      this.connection.removeListener("message.pubsub.publish", this._publish);
      return this.connection.removeListener("disconnect", this._disconnect);
    };

    return Subscription;

  })(EventEmitter);

}).call(this);

//# sourceMappingURL=Subscription.js.map
