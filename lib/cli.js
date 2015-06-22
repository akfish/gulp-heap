var _ = require('underscore');

var minimist = require('minimist');

parserOpts = {
  'default': {
    debug: false
  }
};

var cli = {
  init: function() {

  },
  register: function(opts) {
    parserOpts = _.extend(parserOpts, opts);
  },
  run: function() {
    this.opts = minimist(process.argv, parserOpts);
    return this.opts;
  },
  opts: {}
};

module.exports = cli;
