(function() {
  var Subscriber, Subscription,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  Subscription = require("./Subscription");

  module.exports = Subscriber = (function() {
    function Subscriber(connection) {
      this.connection = connection;
      this.subscribe = __bind(this.subscribe, this);
      this._id = 0;
    }

    Subscriber.prototype.subscribe = function(topic) {
      return new Subscription(this.connection, topic, ++this._id);
    };

    return Subscriber;

  })();

}).call(this);

//# sourceMappingURL=Subscriber.js.map
