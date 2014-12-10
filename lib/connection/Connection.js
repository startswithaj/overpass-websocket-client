(function() {
  var Connection, EventEmitter, JSONStream, Promise, WebSocketFactory, bluebird,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  EventEmitter = require("node-event-emitter");

  JSONStream = require("JSONStream");

  bluebird = require("bluebird");

  Promise = bluebird.Promise;

  WebSocketFactory = require("./WebSocketFactory");

  module.exports = Connection = (function(_super) {
    __extends(Connection, _super);

    function Connection(url, webSocketFactory) {
      this.url = url;
      this.webSocketFactory = webSocketFactory != null ? webSocketFactory : new WebSocketFactory();
      this._parserMessage = __bind(this._parserMessage, this);
      this._parserError = __bind(this._parserError, this);
      this._message = __bind(this._message, this);
      this._close = __bind(this._close, this);
      this._open = __bind(this._open, this);
      this._disconnect = __bind(this._disconnect, this);
      this._connect = __bind(this._connect, this);
      this.send = __bind(this.send, this);
      this.disconnect = __bind(this.disconnect, this);
      this.connect = __bind(this.connect, this);
      this._connectionState = WebSocket.CLOSED;
      this._socket = null;
      this.parser = JSONStream.parse("*");
      this.parser.on("error", this._parserError);
      this.parser.on("data", this._parserMessage);
    }

    Connection.prototype.connect = function(request) {
      if (request == null) {
        request = {};
      }
      switch (this._connectionState) {
        case WebSocket.CONNECTING:
          return this._connectionPromise;
        case WebSocket.OPEN:
          return bluebird.resolve();
        case WebSocket.CLOSING:
          return this._connectionPromise = this._connectionPromise.then((function(_this) {
            return function() {
              return _this._connect(request);
            };
          })(this));
        case WebSocket.CLOSED:
          return this._connectionPromise = this._connect(request);
      }
    };

    Connection.prototype.disconnect = function() {
      switch (this._connectionState) {
        case WebSocket.CONNECTING:
          return this._connectionPromise = this._connectionPromise.then((function(_this) {
            return function() {
              return _this._disconnect();
            };
          })(this));
        case WebSocket.OPEN:
          return this._connectionPromise = this._disconnect();
        case WebSocket.CLOSING:
          return this._connectionPromise;
        case WebSocket.CLOSED:
          return bluebird.resolve();
      }
    };

    Connection.prototype.send = function(message) {
      return this._socket.send(JSON.stringify([message]));
    };

    Connection.prototype._connect = function(request) {
      this._connectionState = WebSocket.CONNECTING;
      return new Promise((function(_this) {
        return function(resolve, reject) {
          _this._socket = _this.webSocketFactory.create(_this.url);
          _this._socket.onopen = function() {
            _this._open(request);
            return resolve();
          };
          return _this._socket.onclose = function() {
            _this._connectionState = WebSocket.CLOSED;
            return reject(new Error("Unable to connect to server."));
          };
        };
      })(this));
    };

    Connection.prototype._disconnect = function() {
      this._connectionState = WebSocket.CLOSING;
      return new Promise((function(_this) {
        return function(resolve, reject) {
          _this.on("disconnect", function() {
            return resolve();
          });
          return _this._socket.close();
        };
      })(this));
    };

    Connection.prototype._open = function(request) {
      this._socket.onclose = this._close;
      this._socket.onmessage = this._message;
      this._connectionState = WebSocket.OPEN;
      return this.send({
        type: "handshake.request",
        version: "1.0.0",
        request: request
      });
    };

    Connection.prototype._close = function(event) {
      this._connectionState = WebSocket.CLOSED;
      this._socket = null;
      return this.emit("disconnect", event.code, event.reason);
    };

    Connection.prototype._message = function(event) {
      return this.parser.write(event.data);
    };

    Connection.prototype._parserError = function(error) {
      this._socket.close(4001, "Invalid message received.");
      this._connectionState = WebSocket.CLOSED;
      return this.emit("error", error);
    };

    Connection.prototype._parserMessage = function(message) {
      switch (message.type) {
        case "handshake.approve":
          return this.emit("connect", message.response);
        case "handshake.reject":
          return this.emit("error", message.reason);
        default:
          return this.emit("message." + message.type, message);
      }
    };

    return Connection;

  })(EventEmitter);

}).call(this);

//# sourceMappingURL=Connection.js.map