(function() {
  var AsyncBinaryState, EventEmitter, HandshakeManager, PersistentConnection, Promise,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  AsyncBinaryState = require("../AsyncBinaryState");

  Promise = require("bluebird");

  EventEmitter = require("node-event-emitter");

  HandshakeManager = require("./HandshakeManager");

  module.exports = PersistentConnection = (function(_super) {
    __extends(PersistentConnection, _super);

    function PersistentConnection(connection, handshakeManager, reconnectWait, reconnectLimit, keepaliveWait) {
      this.connection = connection;
      this.handshakeManager = handshakeManager != null ? handshakeManager : new HandshakeManager();
      this.reconnectWait = reconnectWait != null ? reconnectWait : 3;
      this.reconnectLimit = reconnectLimit != null ? reconnectLimit : 20;
      this.keepaliveWait = keepaliveWait != null ? keepaliveWait : 30;
      this._message = __bind(this._message, this);
      this._reconnect = __bind(this._reconnect, this);
      this._disconnect = __bind(this._disconnect, this);
      this.send = __bind(this.send, this);
      this._state = new AsyncBinaryState();
      this._waitForConnectResolver = null;
    }

    PersistentConnection.prototype.connect = function() {
      return this._state.setOn((function(_this) {
        return function() {
          var buildRequest;
          if (_this._reconnectInterval == null) {
            _this.connection.once("disconnect", _this._reconnect);
          }
          buildRequest = Promise.method(function() {
            return _this.handshakeManager.buildRequest();
          });
          return buildRequest().then(function(request) {
            return _this.connection.connect(request);
          }).then(function(response) {
            var keepalive, wait;
            _this.connection.on("message", _this._message);
            _this.connection.once("disconnect", _this._disconnect);
            keepalive = function() {
              return _this.send({
                type: "connection.heartbeat"
              });
            };
            wait = Math.round(_this.keepaliveWait * 1000);
            _this._keepaliveInterval = setInterval(keepalive, wait);
            _this.handshakeManager.handleResponse(response);
            _this.emit("connect", response);
            if (_this._waitForConnectResolver != null) {
              _this._waitForConnectResolver.resolve(response);
            }
            return response;
          })["catch"](function(error) {
            _this.emit("error", error);
            throw error;
          });
        };
      })(this));
    };

    PersistentConnection.prototype.disconnect = function() {
      return this._state.setOff((function(_this) {
        return function() {
          _this.connection.removeListener("disconnect", _this._reconnect);
          if (_this._reconnectInterval != null) {
            clearInterval(_this._reconnectInterval);
            delete _this._reconnectInterval;
          }
          return _this.connection.disconnect().then(function() {
            return _this.connection.removeListener("message", _this._message);
          });
        };
      })(this));
    };

    PersistentConnection.prototype.send = function(message) {
      return this.connection.send(message);
    };

    PersistentConnection.prototype.waitForConnect = function() {
      if (this._waitForConnectResolver == null) {
        this._waitForConnectResolver = Promise.defer();
        if (this._state.isOn) {
          this._waitForConnectResolver.resolve();
        }
      }
      return this._waitForConnectResolver.promise;
    };

    PersistentConnection.prototype._disconnect = function() {
      this._waitForConnectResolver = null;
      clearInterval(this._keepaliveInterval);
      delete this._keepaliveInterval;
      this._state.setOff();
      return this.emit("disconnect", this);
    };

    PersistentConnection.prototype._reconnect = function() {
      var reconnect, wait;
      reconnect = (function(_this) {
        return function() {
          ++_this._reconnectCount;
          return _this.connect().then(function() {
            clearInterval(_this._reconnectInterval);
            return delete _this._reconnectInterval;
          })["catch"](function() {
            if (this._reconnectCount >= this.reconnectLimit) {
              clearInterval(this._reconnectInterval);
              delete this._reconnectInterval;
              if (this._waitForConnectResolver != null) {
                return this._waitForConnectResolver.reject(new Error("Unable to connect to server."));
              }
            }
          });
        };
      })(this);
      wait = Math.round(this.reconnectWait * 1000);
      this._reconnectCount = 0;
      return this._reconnectInterval = setInterval(reconnect, wait);
    };

    PersistentConnection.prototype._message = function(message) {
      this.emit("message", message);
      return this.emit("message." + message.type, message);
    };

    return PersistentConnection;

  })(EventEmitter);

}).call(this);

//# sourceMappingURL=PersistentConnection.js.map
