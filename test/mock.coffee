console.log("Initialize mock for testing");

STREAM_COUNTER = 0
class MockStream
  constructor: (@src, @srcOpts) ->
    @id = STREAM_COUNTER++
    @name = @src
    @content = []
    @dst = undefined
    @dstOpts = undefined

  pipe: (stream) ->
    return stream.takeOver(@)

  write: (line) ->
    @content.push(line)

  dest: (@dst, @dstOpts) ->

  takeOver: (prevStream) ->
    @src = prevStream.src
    @srcOpts = prevStream.srcOpts
    @dst = prevStream.dst
    @dstOpts = prevStream.dstOpts
    @name = prevStream.name

    @content = prevStream.content.concat(@content)

    @onTakeOver?.bind(@)()

    return @


openRenameStream = (newName) ->
  s = new MockStream()
  s.onTakeOver = ->
    @name = newName

  return s

openWriteStream = (dst, opts) ->
  s = new MockStream()
  s.onTakeOver = ->
    @dest(dst, opts)

  return s

mockProxy =
  createStream: (src, opts) ->
    return new MockStream(src, opts)

  renameStream: (opts) ->
    return openRenameStream(opts)

  writeStream: (dst, opts) ->
    return openWriteStream(dst, opts)

require('../lib/proxy').init(mockProxy)

module.exports.Stream = MockStream

module.exports.makeTask = (name) ->
  raw = (stream, opts) ->
    payload =
      source: name
      opts: opts
    stream.write(payload)

    stream

  raw.payload = (opts = {}) ->
    payload =
      source: name
      opts: opts
    payload

  raw
