var core = require('./core'),
  _ = require('underscore'),
  convert = require('./convert');

var TASK_CACHE = {};

module.paths = _.uniq(module.paths.concat(module.parent.parent.paths));

module.exports = function(path, defaultOpts) {
  if (TASK_CACHE[path]) return TASK_CACHE[path];
  var m = require(path);
  var conv = convert(m, defaultOpts);
  var task = conv.toTask();

  task.asWrapper = function(beginMethod, endMethod, defaultBeginOpts, defaultEndOpts) {
    if (this._as_wrapper) return this._as_wrapper;
    this._as_wrapper = conv.toWrapper.apply(conv, arguments);
    return this._as_wrapper;
  };
  TASK_CACHE[path] = task;
  return task;
};
