gulp = require 'gulp'
path = require 'path'
heap = require './'
mocha = heap.require('gulp-mocha')

mochaOpts =
  require: [path.join(__dirname, '/test/mock')]

gulp.task 'test', mocha(mochaOpts).source('./test/*.spec.coffee', {read: false})
