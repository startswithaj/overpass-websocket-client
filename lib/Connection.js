(function() {
  var Connection, EventEmitter, JSONStream, Promise,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  EventEmitter = require('node-event-emitter');

  JSONStream = require('JSONStream');

  Promise = require('promise');

  module.exports = Connection = (function(_super) {
    __extends(Connection, _super);

    function Connection(url) {
      this.url = url;
      this._onParserData = __bind(this._onParserData, this);
      this._onParserError = __bind(this._onParserError, this);
      this._onConnectionMessage = __bind(this._onConnectionMessage, this);
      this._onConnectionClose = __bind(this._onConnectionClose, this);
      this._onConnectionOpen = __bind(this._onConnectionOpen, this);
      this._doDisconnect = __bind(this._doDisconnect, this);
      this._doConnect = __bind(this._doConnect, this);
      this.send = __bind(this.send, this);
      this.disconnect = __bind(this.disconnect, this);
      this.connect = __bind(this.connect, this);
      this._connectionState = WebSocket.CLOSED;
      this._parser = JSONStream.parse('*');
      this._parser.on('error', this._onParserError);
      this._parser.on('data', this._onParserData);
    }

    Connection.prototype.connect = function() {
      switch (this._connectionState) {
        case WebSocket.CONNECTING:
          return this._connectionPromise;
        case WebSocket.OPEN:
          return Promise.resolve();
        case WebSocket.CLOSING:
          return this._connectionPromise = this._connectionPromise.then((function(_this) {
            return function() {
              return _this._doConnect();
            };
          })(this));
        case WebSocket.CLOSED:
          return this._connectionPromise = this._doConnect();
      }
    };

    Connection.prototype.disconnect = function() {
      switch (this._connectionState) {
        case WebSocket.CONNECTING:
          return this._connectionPromise = this._connectionPromise.then((function(_this) {
            return function() {
              return _this._doDisconnect();
            };
          })(this));
        case WebSocket.OPEN:
          return this._connectionPromise = this._doDisconnect();
        case WebSocket.CLOSING:
          return this._connectionPromise;
        case WebSocket.CLOSED:
          return Promise.resolve();
      }
    };

    Connection.prototype.send = function(message) {
      if (message !== Object(message)) {
        throw new TypeError('Messages must be objects.');
      }
      return this.connect().then((function(_this) {
        return function() {
          return _this._socket.send(JSON.stringify([message]));
        };
      })(this));
    };

    Connection.prototype._doConnect = function() {
      this._connectionState = WebSocket.CONNECTING;
      return new Promise((function(_this) {
        return function(resolve, reject) {
          _this._socket = new WebSocket(_this.url);
          _this._socket.onopen = function() {
            _this._onConnectionOpen();
            return resolve();
          };
          return _this._socket.onclose = function() {
            _this._connectionState = WebSocket.CLOSED;
            _this.emit('error');
            return reject();
          };
        };
      })(this));
    };

    Connection.prototype._doDisconnect = function() {
      return new Promise((function(_this) {
        return function(resolve, reject) {
          return _this._socket.close();
        };
      })(this));
    };

    Connection.prototype._onConnectionOpen = function() {
      this._socket.onclose = this._onConnectionClose;
      this._socket.onmessage = this._onConnectionMessage;
      this._connectionState = WebSocket.OPEN;
      return this.emit('connect');
    };

    Connection.prototype._onConnectionClose = function(event) {
      this._connectionState = WebSocket.CLOSED;
      return this.emit('disconnect', event.code, event.reason);
    };

    Connection.prototype._onConnectionMessage = function(event) {
      return this._parser.write(event.data);
    };

    Connection.prototype._onParserError = function(error) {
      this._socket.close(4001, 'Invalid message received.');
      this._connectionState = WebSocket.CLOSED;
      return this.emit('error', error);
    };

    Connection.prototype._onParserData = function(message) {
      if (message === Object(message)) {
        return this.emit(message.type, message);
      } else {
        return this._onParserError("Invalid message received: " + (JSON.stringify(message)));
      }
    };

    return Connection;

  })(EventEmitter);

}).call(this);

//# sourceMappingURL=Connection.js.map
