(function() {
  var EventEmitter, Promise, Subscription, bluebird, regexEscape,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  bluebird = require("bluebird");

  EventEmitter = require("node-event-emitter");

  regexEscape = require("escape-string-regexp");

  Promise = require("bluebird").Promise;

  module.exports = Subscription = (function(_super) {
    __extends(Subscription, _super);

    function Subscription(connection, topic, id, timeout) {
      var atom, atoms;
      this.connection = connection;
      this.topic = topic;
      this.id = id;
      this.timeout = timeout != null ? timeout : 10;
      this._publish = __bind(this._publish, this);
      this._unsubscribe = __bind(this._unsubscribe, this);
      this._subscribed = __bind(this._subscribed, this);
      this._subscribe = __bind(this._subscribe, this);
      this._subscriber = bluebird.resolve();
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
      this.connection.on("message.pubsub.subscribed", this._subscribed);
      this.connection.on("message.pubsub.publish", this._publish);
    }

    Subscription.prototype.enable = function() {
      return this._subscriber = this._subscriber.then(this._subscribe, this._subscribe);
    };

    Subscription.prototype.disable = function() {
      return this._subscriber = this._subscriber.then(this._unsubscribe, this._unsubscribe);
    };

    Subscription.prototype._subscribe = function() {
      var promise, timeout;
      promise = new Promise((function(_this) {
        return function(resolve) {
          return _this._resolve = resolve;
        };
      })(this));
      this.connection.send({
        type: "pubsub.subscribe",
        id: this.id,
        topic: this.topic
      });
      timeout = Math.round(this.timeout * 1000);
      return promise.timeout(timeout, "Subscription request timed out.");
    };

    Subscription.prototype._subscribed = function(message) {
      if (message.id === this.id) {
        return this._resolve();
      }
    };

    Subscription.prototype._unsubscribe = function() {
      return this.connection.send({
        type: "pubsub.unsubscribe",
        id: this.id
      });
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
