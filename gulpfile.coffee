gulp = require 'gulp'
path = require 'path'
heap = {cli} = require './'
mocha = heap.require('gulp-mocha')

mochaOpts =
  # require: [path.join(__dirname, '/test/mock')]
  grep: cli.opts['only']
  globals: ['chai', 'expect']
  require: [path.join(__dirname, '/test/common')]
  
gulp.task 'test', mocha(mochaOpts).source('./test/*.spec.coffee', {read: false})
