(function() {
  var AsyncBinaryState, Connection, EventEmitter, Promise, TimeoutError, WebSocketFactory, bluebird,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  EventEmitter = require("node-event-emitter");

  bluebird = require("bluebird");

  Promise = bluebird.Promise, TimeoutError = bluebird.TimeoutError;

  WebSocketFactory = require("./WebSocketFactory");

  AsyncBinaryState = require("../AsyncBinaryState");

  module.exports = Connection = (function(_super) {
    __extends(Connection, _super);

    function Connection(url, connectTimeout, webSocketFactory) {
      this.url = url;
      this.connectTimeout = connectTimeout != null ? connectTimeout : 3;
      this.webSocketFactory = webSocketFactory != null ? webSocketFactory : new WebSocketFactory();
      this._message = __bind(this._message, this);
      this._close = __bind(this._close, this);
      this._closeDuringConnect = __bind(this._closeDuringConnect, this);
      this._open = __bind(this._open, this);
      this.send = __bind(this.send, this);
      this.disconnect = __bind(this.disconnect, this);
      this.connect = __bind(this.connect, this);
      this._state = new AsyncBinaryState();
      this._socket = null;
      this._socketResolvers = null;
    }

    Connection.prototype.connect = function(request) {
      if (request == null) {
        request = {};
      }
      return this._state.setOn((function(_this) {
        return function() {
          var promise, timeout;
          promise = new Promise(function(resolve, reject) {
            _this._socketResolvers = {
              resolve: resolve,
              reject: reject
            };
            _this._socket = _this.webSocketFactory.create(_this.url);
            _this._socket.onopen = function() {
              return _this._open(request);
            };
            return _this._socket.onclose = _this._closeDuringConnect;
          });
          timeout = Math.round(_this.connectTimeout * 1000);
          return promise.timeout(timeout, "Connection timed out.")["catch"](TimeoutError, function(error) {
            _this._socket.close(4001, "Connection handshake timed out.");
            throw error;
          });
        };
      })(this));
    };

    Connection.prototype.disconnect = function() {
      return this._state.setOff((function(_this) {
        return function() {
          return new Promise(function(resolve, reject) {
            _this.on("disconnect", function() {
              return resolve();
            });
            return _this._socket.close();
          });
        };
      })(this));
    };

    Connection.prototype.send = function(message) {
      return this._socket.send(JSON.stringify(message));
    };

    Connection.prototype._open = function(request) {
      this._socket.onmessage = this._message;
      return this.send({
        type: "handshake.request",
        version: "1.0.0",
        request: request
      });
    };

    Connection.prototype._closeDuringConnect = function() {
      this._socketResolvers.reject(new Error("Unable to connect to server."));
      return this._socketResolvers = null;
    };

    Connection.prototype._close = function(event) {
      this._state.setOff();
      this._socket = null;
      return this.emit("disconnect", event.code, event.reason);
    };

    Connection.prototype._message = function(event) {
      var error, message;
      try {
        message = JSON.parse(event.data);
      } catch (_error) {
        error = _error;
        this._socket.close(4001, "Invalid message received.");
        this._state.setOff();
        return;
      }
      switch (message.type) {
        case "handshake.approve":
          this._socketResolvers.resolve(message.response);
          this._socketResolvers = null;
          this._socket.onclose = this._close;
          return this.emit("connect", message.response);
        case "handshake.reject":
          this._socketResolvers.reject(message.reason);
          this._socketResolvers = null;
          this._socket.onclose = null;
          this._socket = null;
          return this._state.setOff();
        default:
          return this.emit("message." + message.type, message);
      }
    };

    return Connection;

  })(EventEmitter);

}).call(this);

//# sourceMappingURL=Connection.js.map
