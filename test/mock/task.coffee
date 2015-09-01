{Writer} = require('./stream')
module.exports = (name) ->
  raw = (stream, opts) ->
    sw = new Writer()
    payload =
      source: name
      opts: opts

    sw.enqueue(payload)

    sw

  raw.payload = (opts = {}) ->
    payload =
      source: name
      opts: opts
    payload

  raw.taskName = name

  raw
