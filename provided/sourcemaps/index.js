var core = require('../../core'),
  sourcemaps = require('gulp-sourcemaps');

module.exports = core.wrapper(
  function(stream, opts) {
    console.log('begin sourcemaps');
    return sourcemaps.init(opts);
  },
  function(stream, opts) {
    console.log('end sourcemaps');
    return sourcemaps.write(opts);
  }
);
