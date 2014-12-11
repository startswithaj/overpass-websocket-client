(function() {
  var ExecutionError, InvalidMessageError, Response, ResponseCode, UnknownProcedureError,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  ExecutionError = require('../error/ExecutionError');

  InvalidMessageError = require('../error/InvalidMessageError');

  ResponseCode = require('./ResponseCode');

  UnknownProcedureError = require('../error/UnknownProcedureError');

  module.exports = Response = (function() {
    function Response(code, value) {
      this.code = code;
      this.value = value;
      this.toString = __bind(this.toString, this);
      this.extract = __bind(this.extract, this);
    }

    Response.prototype.extract = function() {
      if (this.code === ResponseCode.SUCCESS) {
        return this.value;
      }
      if (this.code === ResponseCode.INVALID_MESSAGE) {
        throw new InvalidMessageError(this.value);
      }
      if (this.code === ResponseCode.UNKNOWN_PROCEDURE) {
        throw new UnknownProcedureError(this.value);
      }
      throw new ExecutionError(this.value);
    };

    Response.prototype.toString = function() {
      var valueString;
      valueString = this.code.is('SUCCESS') ? JSON.stringify(this.value) : this.value;
      return this.code.key + '(' + valueString + ')';
    };

    return Response;

  })();

}).call(this);

//# sourceMappingURL=Response.js.map
