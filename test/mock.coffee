console.log("Initialize mock for testing");
_ = require 'underscore'

STREAM_COUNTER = 0
class MockFS
  constructor: ->
    @_storage = {}

  open: (ns) ->
    if not @_storage[ns]?
      @_storage[ns] = {}
    @_currentNs = ns

  _getCurrentNs: ->
    if not @_currentNs? then throw new Error("MockFS.ns not set")
    return @_storage[@_currentNs]

  write: (dst, name, content, opts) ->
    ns = @_getCurrentNs()

    ns[dst] =
      name: name
      content: content
      opts: opts

  read: (dst) ->
    ns = @_getCurrentNs()

    ns[dst]

FS = new MockFS()

class MockStream
  @FS: FS
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
    @constructor.FS.write(@dst, @name, @content.map((item) -> _.clone(item)), @dstOpts)

  takeOver: (prevStream) ->
    @src ?= prevStream.src
    @srcOpts ?= prevStream.srcOpts
    @dst ?= prevStream.dst
    @dstOpts ?= prevStream.dstOpts
    @name ?= prevStream.name

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

  mergeStreams: (streams) ->
    merged = new MockStream();

    streams.forEach((s) -> s.pipe(merged))

    return merged

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

module.exports.FS = FS
