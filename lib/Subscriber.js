(function() {
  var EventEmitter, Subscriber,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  EventEmitter = require('node-event-emitter');

  module.exports = Subscriber = (function(_super) {
    __extends(Subscriber, _super);

    function Subscriber(connection) {
      this.connection = connection;
      this._onPublish = __bind(this._onPublish, this);
      this.unsubscribe = __bind(this.unsubscribe, this);
      this.subscribe = __bind(this.subscribe, this);
      this.connection.on('pubsub.publish', this._onPublish);
    }

    Subscriber.prototype.subscribe = function(topic) {
      return this.connection.send({
        type: 'pubsub.subscribe',
        topic: topic
      });
    };

    Subscriber.prototype.unsubscribe = function(topic) {
      return this.connection.send({
        type: 'pubsub.unsubscribe',
        topic: topic
      });
    };

    Subscriber.prototype._onPublish = function(message) {
      this.emit("message", message.topic, message.payload);
      return this.emit("message." + message.topic, message.topic, message.payload);
    };

    return Subscriber;

  })(EventEmitter);

}).call(this);

//# sourceMappingURL=Subscriber.js.map
