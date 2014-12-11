(function() {
  var InvalidMessageError, Promise, Request, Response, ResponseCode, RpcClient, bluebird,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    __slice = [].slice;

  bluebird = require('bluebird');

  Promise = require('bluebird').Promise;

  InvalidMessageError = require('./error/InvalidMessageError');

  Request = require('./message/Request');

  Response = require('./message/Response');

  ResponseCode = require('./message/ResponseCode');

  module.exports = RpcClient = (function() {
    function RpcClient(connection, timeout) {
      this.connection = connection;
      this.timeout = timeout != null ? timeout : 10;
      this._recv = __bind(this._recv, this);
      this._send = __bind(this._send, this);
      this.invokeArray = __bind(this.invokeArray, this);
      this.invoke = __bind(this.invoke, this);
      this._requests = {};
      this._id = 0;
      this.connection.on("message.rpc.response", this._recv);
    }

    RpcClient.prototype.invoke = function() {
      var args, id, name, request;
      name = arguments[0], args = 2 <= arguments.length ? __slice.call(arguments, 1) : [];
      id = (++this._id).toString();
      request = new Request(name, args);
      return this._send(request, id).then((function(_this) {
        return function(response) {
          return response.extract();
        };
      })(this));
    };

    RpcClient.prototype.invokeArray = function(name, args) {
      return this.invoke.apply(this, [name].concat(__slice.call(args)));
    };

    RpcClient.prototype._send = function(request, id) {
      var promise, timeout;
      promise = new Promise((function(_this) {
        return function(resolve, reject) {
          _this._requests[id] = {
            resolve: resolve,
            reject: reject
          };
          return _this.connection.send({
            type: "rpc.request",
            id: id,
            name: request.name,
            "arguments": request["arguments"]
          });
        };
      })(this));
      timeout = Math.round(this.timeout * 1000);
      return promise.timeout(timeout, 'RPC request timed out.')["finally"]((function(_this) {
        return function() {
          return delete _this._requests[id];
        };
      })(this));
    };

    RpcClient.prototype._recv = function(message) {
      var code, error;
      if (message.id == null) {
        return;
      }
      if (this._requests[message.id] == null) {
        return;
      }
      if (!(code = ResponseCode.get(message.code))) {
        error = new InvalidMessageError('Response code is unrecognised.');
        this.connection.close(4001, error.message);
        return this._requests[message.id].reject(error);
      }
      if (code !== ResponseCode.SUCCESS && typeof message.value !== 'string') {
        error = new InvalidMessageError('Response error message must be a string.');
        this.connection.close(4001, error.message);
        return this._requests[message.id].reject(error);
      }
      return this._requests[message.id].resolve(new Response(code, message.value));
    };

    return RpcClient;

  })();

}).call(this);

//# sourceMappingURL=RpcClient.js.map
