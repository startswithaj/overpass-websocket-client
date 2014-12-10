(function() {
  var WebSocketFactory;

  module.exports = WebSocketFactory = (function() {
    function WebSocketFactory(webSocketClass) {
      this.webSocketClass = webSocketClass != null ? webSocketClass : WebSocket;
    }

    WebSocketFactory.prototype.create = function(url, protocols) {
      return new this.webSocketClass(url, protocols);
    };

    return WebSocketFactory;

  })();

}).call(this);

//# sourceMappingURL=WebSocketFactory.js.map
