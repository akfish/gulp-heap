var fs = require('fs'),
  path = require('path'),
  cli = require('./cli'),
  proxy = require('./proxy');

proxy.init(require('./gulp-proxy'));
cli.init();

var providedDir = path.join(__dirname, '/provided');

fs.readdirSync(providedDir).forEach(function(file) {
  var p = path.resolve(providedDir +  '/', file +  '/index.js');
  if (fs.existsSync(p)) {
    module.exports[file] = require(p);
  }
});

module.exports.cli = cli;
module.exports.require = require('./require');
module.exports.convert = require('./convert');

if (cli.run().debug) console.log(cli.opts);
