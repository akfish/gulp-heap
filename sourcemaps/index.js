var core = require('../core'),
  sourcemaps = require('gulp-sourcemaps');

module.exports = core.wrapper(
  function(stream, opts) {
    console.log('init');
    return sourcemaps.init(opts);
  },
  function(stream, opts) {
    console.log('end');
    return sourcemaps.write(opts);
  }
);
