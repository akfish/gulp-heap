{Stream, makeTask} = require('./mock')

payload = (name, opts = {}) ->
  p =
    source: name
    opts: opts
  p

mockRun = (name, opts) ->
  s = new Stream()
  s.write(payload(name, opts))
  s


W =
  before: (opts) ->
    mockRun('w:before', opts)
  after: (opts) ->
    mockRun('w:after', opts)

W.before.payload = payload.bind(undefined, 'w:before')
W.after.payload = payload.bind(undefined, 'w:after')

module.exports = W
