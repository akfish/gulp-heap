var fs = require('fs'),
  path = require('path'),
  cli = require('./cli');

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

if (cli.run().debug) console.log(cli.opts);
