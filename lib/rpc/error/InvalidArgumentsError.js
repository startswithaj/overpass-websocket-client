(function() {
  var InvalidArgumentsError, ResponseCode,
    extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    hasProp = {}.hasOwnProperty;

  ResponseCode = require('../message/ResponseCode');

  module.exports = InvalidArgumentsError = (function(superClass) {
    extend(InvalidArgumentsError, superClass);

    function InvalidArgumentsError(message) {
      this.message = message;
      this.responseCode = ResponseCode.INVALID_ARGUMENTS;
    }

    return InvalidArgumentsError;

  })(Error);

}).call(this);

//# sourceMappingURL=InvalidArgumentsError.js.map
