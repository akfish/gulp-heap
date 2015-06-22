var gulp = require('gulp'),
  gutil = require('gulp-util'),
  rename = require('gulp-rename'),
  plumber = require('gulp-plumber');

module.exports = {
  createStream: function(src, opts) {
    return gulp.src(src, opts).on('error', gutil.log).pipe(plumber());
  },
  renameStream: function(opts) {
    return rename(opts);
  },
  writeStream: function(dst, opts) {
    return gulp.dest(dst, opts);
  },
};
