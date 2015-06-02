var coffee = require('gulp-coffee'),
  core = require('../core'),
  _ = require('underscore');

DEFAULT_OPTS = {
  bare: true
};

// function compileCoffee(src, dst, opts) {
//   var o = _.defaults(DEFAULT_OPTS, opts);
//   var g = gulp.src(src);
//   if (o.sourceMap) g.pipe(sourcemaps.init());
//   g.pipe(coffee(o)).on('error', gutil.log);
//   if (o.sourceMap) g.pipe(sourcemaps.write());
//   g.pipe(gulp.dest(dst));
// }

// module.exports = function(src, dst, opts) {
//   return compileCoffee.bind(undefined, src, dst, opts);
// };

module.exports = core.task(function(stream, opts) {
  console.log('coffee');
  return coffee(opts);
}, DEFAULT_OPTS);
