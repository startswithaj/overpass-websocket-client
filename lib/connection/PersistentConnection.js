(function() {
  var AsyncBinaryState, HandshakeManager, PersistentConnection, bluebird,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  AsyncBinaryState = require("../AsyncBinaryState");

  bluebird = require("bluebird");

  HandshakeManager = require("./HandshakeManager");

  module.exports = PersistentConnection = (function(_super) {
    __extends(PersistentConnection, _super);

    function PersistentConnection(connection, handshakeManager, reconnectWait, keepaliveWait) {
      this.connection = connection;
      this.handshakeManager = handshakeManager != null ? handshakeManager : new HandshakeManager();
      this.reconnectWait = reconnectWait != null ? reconnectWait : 3;
      this.keepaliveWait = keepaliveWait != null ? keepaliveWait : 30;
      this._reconnect = __bind(this._reconnect, this);
      this._disconnect = __bind(this._disconnect, this);
      this.send = __bind(this.send, this);
      this._state = new AsyncBinaryState();
    }

    PersistentConnection.prototype.connect = function() {
      return this._state.setOn((function(_this) {
        return function() {
          _this.connection.once("disconnect", _this._reconnect);
          return bluebird.method(function() {
            return _this.handshakeManager.buildRequest();
          }).then(function(request) {
            return _this.connection.connect(request);
          }).then(function(response) {
            var keepalive, wait;
            _this.connection.once("disconnect", _this._disconnect);
            keepalive = function() {};
            wait = Math.round(_this.keepaliveWait * 1000);
            _this._keepaliveInterval = setInterval(keepalive, wait);
            _this.handshakeManager.handleResponse(response);
            _this.emit("connect", response);
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
          return _this.connection.disconnect();
        };
      })(this));
    };

    PersistentConnection.prototype.send = function(message) {
      return this.connect.send(message);
    };

    PersistentConnection.prototype.waitForConnect = function() {
      if (this._state.isOn) {
        return bluebird.resolve();
      }
      return new Promise((function(_this) {
        return function(resolve, reject) {
          _this.once("connect", function() {
            return resolve();
          });
          return _this.once("error", function() {
            return reject();
          });
        };
      })(this));
    };

    PersistentConnection.prototype._disconnect = function() {
      clearInterval(this._keepaliveInterval);
      delete this._keepaliveInterval;
      this._state.setOff();
      return this.emit("disconnect", this);
    };

    PersistentConnection.prototype._reconnect = function() {
      var reconnect, wait;
      reconnect = (function(_this) {
        return function() {
          return _this.connect().then(function() {
            clearInterval(_this._reconnectInterval);
            return delete _this._reconnectInterval;
          });
        };
      })(this);
      wait = Math.round(this.reconnectWait * 1000);
      return this._reconnectInterval = setInterval(reconnect, wait);
    };

    return PersistentConnection;

  })(EventEmitter);

}).call(this);

//# sourceMappingURL=PersistentConnection.js.map