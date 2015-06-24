var gulp = require('gulp'),
  gutil = require('gulp-util'),
  rename = require('gulp-rename'),
  plumber = require('gulp-plumber'),
  merge = require('merge2');

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
  mergeStreams: function(streams) {
    return merge(streams);
  }
};
