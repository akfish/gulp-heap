var util = require('./util');

function Wrapper(beginWrapper, EndWrapper, beginOpts, endOpts) {
  this.isWrapper = true;
  this.toggled = true;
  this.beginOpts = beginOpts;
  this.endOpts = endOpts;
  this.begin = beginWrapper;
  this.end = EndWrapper;
}

Wrapper.make = function(beginWrapper, EndWrapper, defaultBeginOpts, defaultEndOpts) {
  return function(beginOpts, endOpts) {
    var oBegin = util.defaults(defaultBeginOpts, beginOpts),
      oEnd = util.defaults(defaultEndOpts, endOpts);
    return new Wrapper(beginWrapper, EndWrapper, oBegin, oEnd);
  };
};

module.exports = Wrapper;
