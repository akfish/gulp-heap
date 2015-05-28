var gulp = require('gulp');
var gutil = require('gulp-util');
var coffee = require('gulp-coffee');
var sourcemaps = require('gulp-sourcemaps');
var _ = require('underscore');

DEFAULT_OPTS = {
  bare: true,
  sourceMap: true
};

function compileCoffee(src, dst, opts) {
  var o = _.defaults(DEFAULT_OPTS, opts);
  var g = gulp.src(src);
  if (o.sourceMap) g.pipe(sourcemaps.init());
  g.pipe(coffee(o)).on('error', gutil.log);
  if (o.sourceMap) g.pipe(sourcemaps.write());
  g.pipe(gulp.dest(dst));
}

module.exports = function(src, dst, opts) {
  return compileCoffee.bind(undefined, src, dst, opts);
};
