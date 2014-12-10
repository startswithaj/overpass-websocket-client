(function() {
  var EventEmitter, Subscriber, regexEscape,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  EventEmitter = require("node-event-emitter");

  regexEscape = require("escape-string-regexp");

  module.exports = Subscriber = (function(_super) {
    __extends(Subscriber, _super);

    function Subscriber(connection) {
      this.connection = connection;
      this._onRemoveListener = __bind(this._onRemoveListener, this);
      this._onNewListener = __bind(this._onNewListener, this);
      this._publish = __bind(this._publish, this);
      this.unsubscribe = __bind(this.unsubscribe, this);
      this.subscribe = __bind(this.subscribe, this);
      this._wildcardListeners = {};
      this.on("newListener", this._onNewListener);
      this.on("removeListener", this._onRemoveListener);
      this.connection.on("message.pubsub.publish", this._publish);
    }

    Subscriber.prototype.subscribe = function(topic) {
      return this.connection.send({
        type: "pubsub.subscribe",
        topic: topic
      });
    };

    Subscriber.prototype.unsubscribe = function(topic) {
      return this.connection.send({
        type: "pubsub.unsubscribe",
        topic: topic
      });
    };

    Subscriber.prototype._publish = function(message) {
      var event, regex, _ref, _results;
      this.emit("message", message.topic, message.payload);
      this.emit("message." + message.topic, message.topic, message.payload);
      _ref = this._wildcardListeners;
      _results = [];
      for (event in _ref) {
        regex = _ref[event];
        if (regex.test(message.topic)) {
          _results.push(this.emit(event, message.topic, message.payload));
        } else {
          _results.push(void 0);
        }
      }
      return _results;
    };

    Subscriber.prototype._onNewListener = function(event, listener) {
      var atom, atoms, isPattern;
      if (event in this._wildcardListeners) {
        return;
      }
      atoms = event.split(".");
      if (atoms.shift() !== "message") {
        return;
      }
      isPattern = false;
      atoms = (function() {
        var _i, _len, _results;
        _results = [];
        for (_i = 0, _len = atoms.length; _i < _len; _i++) {
          atom = atoms[_i];
          switch (atom) {
            case "*":
              isPattern = true;
              _results.push("(.+)");
              break;
            case "?":
              isPattern = true;
              _results.push("([^.]+)");
              break;
            default:
              _results.push(regexEscape(atom));
          }
        }
        return _results;
      })();
      if (isPattern) {
        return this._wildcardListeners[event] = new RegExp("^" + (atoms.join(regexEscape("."))) + "$");
      }
    };

    Subscriber.prototype._onRemoveListener = function(event, listener) {
      if (!EventEmitter.listenerCount(this, event)) {
        return delete this._wildcardListeners[event];
      }
    };

    return Subscriber;

  })(EventEmitter);

}).call(this);

//# sourceMappingURL=Subscriber.js.map
