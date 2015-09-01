{Writer} = require('./stream')

name = 'foo'

payload = (opts = {}) ->
  p =
    source: name
    opts: opts
  p

module.exports = (opts) ->
  s = new Writer()
  s.enqueue(payload(opts))
  s

module.exports.payload = payload
