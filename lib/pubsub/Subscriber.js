(function() {
  var Subscriber, Subscription,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  Subscription = require("./Subscription");

  module.exports = Subscriber = (function() {
    function Subscriber(connection, timeout) {
      this.connection = connection;
      this.timeout = timeout != null ? timeout : 3;
      this.subscribe = __bind(this.subscribe, this);
      this._id = 0;
    }

    Subscriber.prototype.subscribe = function(topic) {
      return new Subscription(this.connection, topic, ++this._id, this.timeout);
    };

    return Subscriber;

  })();

}).call(this);

//# sourceMappingURL=Subscriber.js.map
