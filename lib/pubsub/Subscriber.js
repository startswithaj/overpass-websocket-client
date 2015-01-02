(function() {
  var Subscriber, Subscription,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  Subscription = require("./Subscription");

  module.exports = Subscriber = (function() {
    function Subscriber(connection) {
      this.connection = connection;
      this.create = __bind(this.create, this);
      this._id = 0;
    }

    Subscriber.prototype.create = function(topic) {
      return new Subscription(this.connection, topic, ++this._id);
    };

    return Subscriber;

  })();

}).call(this);

//# sourceMappingURL=Subscriber.js.map
