var _ = require('underscore');

function noImp() {
  throw new Error("Not implemented.");
}

var proxy = {
  createStream: function(src, opts) { noImp(); },
  renameStream: function(opts) { noImp(); },
  writeStream: function(dst, opts) { noImp(); },
  init: function(p) {
    _.extend(proxy, p);
  }
};

module.exports = proxy;
