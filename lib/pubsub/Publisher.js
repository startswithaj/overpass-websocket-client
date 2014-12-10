(function() {
  var Publisher,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  module.exports = Publisher = (function() {
    function Publisher(connection) {
      this.connection = connection;
      this.publish = __bind(this.publish, this);
    }

    Publisher.prototype.publish = function(topic, payload) {
      return this.connection.send({
        type: "pubsub.publish",
        topic: topic,
        payload: payload
      });
    };

    return Publisher;

  })();

}).call(this);

//# sourceMappingURL=Publisher.js.map
