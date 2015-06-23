var core = require('./core'),
  _ = require('underscore');

var Convertor = function(m, defaultOpts) {
  this.m = m;
  this.defaultOpts = defaultOpts;
};

Convertor.prototype.toTask = function() {
  if (!this._task) {
    var m = this.m;
    this._task = core.task(function(stream, opts) {
      return m.call(undefined, stream, opts);
    }, this.defaultOpts);
  }
  return this._task;
};

Convertor.prototype.toWrapper = function(beginMethod, endMethod, defaultBeginOpts, defaultEndOpts) {
  var m = this.m;

  var wrapper = core.wrapper(
      function(stream, opts) {
        return m[beginMethod].call(undefined, stream, opts);
      },
      function(stream, opts) {
        return m[endMethod].call(undefined, stream, opts);
      },
      defaultBeginOpts, defaultEndOpts
    );
  return wrapper;
};

module.exports = function(m, defaultOpts) {
  return new Convertor(m, defaultOpts);
};
