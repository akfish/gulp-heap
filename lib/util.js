var _ = require('underscore');

module.exports = util = {
  defaults: function(defaultOpts, opts) {
    if (_.isString(opts) || _.isFunction(opts)) return opts;
    return _.defaults({}, opts, defaultOpts);
  }
};
