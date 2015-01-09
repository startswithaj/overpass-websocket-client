(function() {
  var AsyncBinaryState, EventEmitter, Promise, Subscription, TimeoutError, bluebird, regexEscape,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  bluebird = require("bluebird");

  EventEmitter = require("node-event-emitter");

  regexEscape = require("escape-string-regexp");

  Promise = require("bluebird").Promise;

  TimeoutError = require("bluebird").TimeoutError;

  AsyncBinaryState = require("../AsyncBinaryState");

  module.exports = Subscription = (function(_super) {
    __extends(Subscription, _super);

    function Subscription(connection, topic, id, timeout) {
      var atom, atoms;
      this.connection = connection;
      this.topic = topic;
      this.id = id;
      this.timeout = timeout != null ? timeout : 3;
      this._publish = __bind(this._publish, this);
      this._subscribed = __bind(this._subscribed, this);
      this._state = new AsyncBinaryState();
      atoms = (function() {
        var _i, _len, _ref, _results;
        _ref = topic.split(".");
        _results = [];
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          atom = _ref[_i];
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
          _this.connection.send({
            type: "pubsub.subscribe",
            id: _this.id,
            topic: _this.topic
          });
          timeout = Math.round(_this.timeout * 1000);
          return promise.timeout(timeout, "Subscription request timed out.")["catch"](TimeoutError, function(error) {
            _this.connection.removeListener("message.pubsub.subscribed", _this._subscribed);
            _this.connection.removeListener("message.pubsub.publish", _this._publish);
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
          _this.connection.removeListener("message.pubsub.subscribed", _this._subscribed);
          return _this.connection.removeListener("message.pubsub.publish", _this._publish);
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

    return Subscription;

  })(EventEmitter);

}).call(this);

//# sourceMappingURL=Subscription.js.map
