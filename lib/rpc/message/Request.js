(function() {
  var Request,
    bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  module.exports = Request = (function() {
    function Request(name, _arguments) {
      this.name = name;
      this["arguments"] = _arguments;
      this.toString = bind(this.toString, this);
    }

    Request.prototype.toString = function() {
      return this.name + '(' + this["arguments"].map(JSON.stringify).join(', ') + ')';
    };

    return Request;

  })();

}).call(this);

//# sourceMappingURL=Request.js.map
