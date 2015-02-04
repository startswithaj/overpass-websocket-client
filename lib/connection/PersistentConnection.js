(function() {
  var AsyncBinaryState, EventEmitter, HandshakeManager, PersistentConnection, Promise,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    __slice = [].slice;

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
      this._handleReconnect = __bind(this._handleReconnect, this);
      this._reconnect = __bind(this._reconnect, this);
      this._disconnect = __bind(this._disconnect, this);
      this.send = __bind(this.send, this);
      this._state = new AsyncBinaryState();
      this._waitForConnectResolver = null;
    }

    PersistentConnection.prototype.connect = function() {
      return this._connect();
    };

    PersistentConnection.prototype.disconnect = function() {
      return this._state.setOff((function(_this) {
        return function() {
          _this.connection.removeListener("disconnect", _this._reconnect);
          _this._cancelReconnect();
          return _this.connection.disconnect().then(function() {
            return _this.connection.removeListener("message", _this._message);
          });
        };
      })(this));
    };

    PersistentConnection.prototype._connect = function(isReconnect) {
      if (isReconnect == null) {
        isReconnect = false;
      }
      return this._state.setOn((function(_this) {
        return function() {
          var buildRequest;
          buildRequest = Promise.method(function() {
            return _this.handshakeManager.buildRequest();
          });
          return buildRequest().then(function(request) {
            return _this.connection.connect(request);
          })["catch"](function(error) {
            if (!isReconnect) {
              _this._reconnect();
            }
            throw error;
          }).then(function(response) {
            var keepalive, wait;
            _this.connection.on("message", _this._message);
            _this.connection.once("disconnect", _this._disconnect);
            _this.connection.once("disconnect", _this._reconnect);
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
            _this.connection.removeListener("message", _this._message);
            _this.connection.removeListener("disconnect", _this._disconnect);
            _this.connection.removeListener("disconnect", _this._reconnect);
            _this.emit("error", error);
            throw error;
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
      return this.emit.apply(this, ["disconnect"].concat(__slice.call(arguments)));
    };

    PersistentConnection.prototype._reconnect = function() {
      if (this._reconnectTimeout != null) {
        return;
      }
      this._reconnectCount = 0;
      return this._scheduleReconnect();
    };

    PersistentConnection.prototype._scheduleReconnect = function() {
      var wait;
      wait = Math.round(this.reconnectWait * 1000);
      return this._reconnectTimeout = setTimeout(this._handleReconnect, wait);
    };

    PersistentConnection.prototype._cancelReconnect = function() {
      if (this._reconnectTimeout != null) {
        clearTimeout(this._reconnectTimeout);
        return delete this._reconnectTimeout;
      }
    };

    PersistentConnection.prototype._handleReconnect = function() {
      var isLastAttempt;
      isLastAttempt = ++this._reconnectCount >= this.reconnectLimit;
      if (isLastAttempt) {
        this._cancelReconnect();
      }
      return this._connect(true).tap((function(_this) {
        return function() {
          return _this._cancelReconnect();
        };
      })(this))["catch"]((function(_this) {
        return function(error) {
          if (isLastAttempt) {
            if (_this._waitForConnectResolver != null) {
              _this._waitForConnectResolver.reject(error);
            }
            return _this.emit("reconnectFailure", error, _this);
          } else {
            return _this._scheduleReconnect();
          }
        };
      })(this));
    };

    PersistentConnection.prototype._message = function(message) {
      this.emit.apply(this, ["message"].concat(__slice.call(arguments)));
      return this.emit.apply(this, ["message." + message.type].concat(__slice.call(arguments)));
    };

    return PersistentConnection;

  })(EventEmitter);

}).call(this);

//# sourceMappingURL=PersistentConnection.js.map
