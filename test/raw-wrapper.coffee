{makeTask} = require('./mock')

module.exports = rawWrapper =
  before: makeTask('w:before')
  after: makeTask('w:after')
