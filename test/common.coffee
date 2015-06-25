GLOBAL.chai = require 'chai'
GLOBAL.Assertion = chai.Assertion
GLOBAL.expect = chai.expect

chai.use require('chai-as-promised')

require('./mock')

chai.use require('./mock/helper')

old_log = console.log.bind(console)

console.log = ->
  trace = new Error().stack.split("\n")[2]

  if trace.indexOf('node_modules') < 0
    old_log trace
  old_log.apply console, arguments
