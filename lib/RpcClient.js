(function() {
  var RpcClient,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    __slice = [].slice;

  module.exports = RpcClient = (function() {
    function RpcClient(connection) {
      this.connection = connection;
      this.invokeArray = __bind(this.invokeArray, this);
      this.invoke = __bind(this.invoke, this);
    }

    RpcClient.prototype.invoke = function() {
      var args, name;
      name = arguments[0], args = 2 <= arguments.length ? __slice.call(arguments, 1) : [];
      return this.invokeArray(name, args);
    };

    RpcClient.prototype.invokeArray = function(name, args) {
      return this.connection.send({
        type: 'rpc.request',
        name: name,
        "arguments": arguments
      });
    };

    return RpcClient;

  })();

}).call(this);

//# sourceMappingURL=RpcClient.js.map
