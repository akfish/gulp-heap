var Task = require('./task'),
  _ = require('underscore');

function defaults(defaultOpts, opts) {
  if (_.isString(opts) || _.isFunction(opts)) return opts;
  return _.defaults({}, opts, defaultOpts);
}

function wrapper(beginWrapper, EndWrapper, beginOpts, endOpts) {
  return {
    isWrapper: true,
    toggled: true,
    beginOpts: beginOpts,
    endOpts: endOpts,
    begin: beginWrapper,
    end: EndWrapper
  };
}

function makeWrapper(beginWrapper, EndWrapper, defaultBeginOpts, defaultEndOpts) {
  return function(beginOpts, endOpts) {
    var oBegin = defaults(defaultBeginOpts, beginOpts),
      oEnd = defaults(defaultEndOpts, endOpts);
    return wrapper(beginWrapper, EndWrapper, oBegin, oEnd);
  };
}

module.exports.task = Task.make;
module.exports.wrapper = makeWrapper;
