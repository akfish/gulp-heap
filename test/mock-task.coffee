{Stream, makeTask} = require('./mock')

name = 'foo'

payload = (opts = {}) ->
  p =
    source: name
    opts: opts
  p

module.exports = (opts) ->
  s = new Stream()
  s.write(payload(opts))
  s

module.exports.payload = payload
