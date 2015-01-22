(function() {
  var AsyncBinaryState, EventEmitter, Promise, Subscription, TimeoutError, regexEscape, _ref,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  AsyncBinaryState = require("../AsyncBinaryState");

  EventEmitter = require("node-event-emitter");

  regexEscape = require("escape-string-regexp");

  _ref = require("bluebird"), Promise = _ref.Promise, TimeoutError = _ref.TimeoutError;

  module.exports = Subscription = (function(_super) {
    __extends(Subscription, _super);

    function Subscription(connection, topic, id, timeout) {
      var atom, atoms;
      this.connection = connection;
      this.topic = topic;
      this.id = id;
      this.timeout = timeout != null ? timeout : 3;
      this._removeListeners = __bind(this._removeListeners, this);
      this._disconnect = __bind(this._disconnect, this);
      this._publish = __bind(this._publish, this);
      this._subscribed = __bind(this._subscribed, this);
      this._state = new AsyncBinaryState();
      atoms = (function() {
        var _i, _len, _ref1, _results;
        _ref1 = topic.split(".");
        _results = [];
        for (_i = 0, _len = _ref1.length; _i < _len; _i++) {
          atom = _ref1[_i];
          switch (atom) {
            case "*":
              _results.push("(.+)");
              break;
            case "?":
              _results.push("([^.]+)");
              break;
            default:
              _results.push(regexEscape(atom));
          }
        }
        return _results;
      })();
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
