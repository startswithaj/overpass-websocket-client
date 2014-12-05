(function() {
  var WebSocketFactory;

  module.exports = WebSocketFactory = (function() {
    function WebSocketFactory(webSocketClass) {
      this.webSocketClass = webSocketClass != null ? webSocketClass : WebSocket;
    }

    WebSocketFactory.prototype.create = function() {
      return (function(func, args, ctor) {
        ctor.prototype = func.prototype;
        var child = new ctor, result = func.apply(child, args);
        return Object(result) === result ? result : child;
      })(this.webSocketClass, arguments, function(){});
    };

    return WebSocketFactory;

  })();

}).call(this);

//# sourceMappingURL=WebSocketFactory.js.map
