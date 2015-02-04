(function() {
  var AsyncBinaryState, Connection, EventEmitter, Promise, TimeoutError, WebSocketFactory, _ref,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  EventEmitter = require("node-event-emitter");

  _ref = require("bluebird"), Promise = _ref.Promise, TimeoutError = _ref.TimeoutError;

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
      this._send = __bind(this._send, this);
      this.send = __bind(this.send, this);
      this.disconnect = __bind(this.disconnect, this);
      this.connect = __bind(this.connect, this);
      this._state = new AsyncBinaryState();
      this._socket = null;
      this._connectionResolver = null;
    }

    Connection.prototype.connect = function(request) {
      if (request == null) {
        request = {};
      }
      return this._connectPromise = this._state.setOn((function(_this) {
        return function() {
          var timeout;
          _this._connectionResolver = Promise.defer();
          _this._socket = _this.webSocketFactory.create(_this.url);
          _this._socket.onopen = function() {
            return _this._open(request);
          };
          _this._socket.onclose = _this._closeDuringConnect;
          timeout = Math.round(_this.connectTimeout * 1000);
          return _this._connectionResolver.promise.timeout(timeout, "Connection timed out.")["catch"](TimeoutError, function(error) {
            _this._socket.close(4001, "Connection handshake timed out.");
            throw error;
          });
        };
      })(this));
    };

    Connection.prototype.disconnect = function() {
      var deferred;
      deferred = Promise.defer();
      this._state.setOff((function(_this) {
        return function() {
          deferred.promise.tap(function() {
            return _this.emit("disconnect", 1000, "Connection terminated by client.");
          })["catch"](function() {});
          _this._socket.onopen = function() {};
          _this._socket.onclose = function() {};
          _this._socket.onmessage = function() {};
          _this._socket.close();
          return _this._socket = null;
        };
      })(this));
      deferred.resolve();
      return deferred.promise;
    };

    Connection.prototype.send = function(message) {
      if (this._state.isOn) {
        return this._send(message);
      } else {
        throw new Error("Unable to send message. Not connected.");
      }
    };

    Connection.prototype._send = function(message) {
      return this._socket.send(JSON.stringify(message));
    };

    Connection.prototype._open = function(request) {
      this._socket.onmessage = this._message;
      return this._send({
        type: "handshake.request",
        version: "1.0.0",
        request: request
      });
    };

    Connection.prototype._closeDuringConnect = function() {
      this._connectionResolver.reject(new Error("Unable to connect to server."));
      return this._connectionResolver = null;
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
          this._connectPromise.then((function(_this) {
            return function() {
              return _this.emit("connect", message.response);
            };
          })(this));
          this._connectionResolver.resolve(message.response);
          this._connectionResolver = null;
          return this._socket.onclose = this._close;
        case "handshake.reject":
          this._connectionResolver.reject(new Error(message.reason));
          this._connectionResolver = null;
          this._socket.onclose = null;
          this._socket = null;
          return this._state.setOff();
        default:
          this.emit("message", message);
          return this.emit("message." + message.type, message);
      }
    };

    return Connection;

  })(EventEmitter);

}).call(this);

//# sourceMappingURL=Connection.js.map
