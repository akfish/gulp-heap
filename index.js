var fs = require('fs'),
  path = require('path');

fs.readdirSync(__dirname).forEach(function(file) {
  var p = path.resolve(__dirname +  '/', file +  '/index.js');
  if (fs.existsSync(p)) {
    module.exports[file] = require(p);
  }
});
