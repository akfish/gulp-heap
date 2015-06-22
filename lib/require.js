var core = require('./core'),
  _ = require('underscore');

var TASK_CACHE = {};

module.paths = _.uniq(module.paths.concat(module.parent.parent.paths));

module.exports = function(path, defaultOpts) {
  if (TASK_CACHE[path]) return TASK_CACHE[path];
  var m = require(path);
  var task = core.task(function(stream, opts) {
    return m.call(undefined, opts);
  }, defaultOpts);
  task.asWrapper = function(beginMethod, endMethod, defaultBeginOpts, defaultEndOpts) {
    if (this._as_wrapper) return this._as_wrapper;
    this._as_wrapper = core.wrapper(
      function(stream, opts) {
        return m[beginMethod].call(undefined, opts);
      },
      function(stream, opts) {
        return m[endMethod].call(undefined, opts);
      },
      defaultBeginOpts, defaultEndOpts
    );
    return this._as_wrapper;
  };
  TASK_CACHE[path] = task;
  return task;
};
