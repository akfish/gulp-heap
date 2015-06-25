through = require('through2')
Stream = require('stream')
Promise = require('bluebird')

File = require('./file')

Base = through.ctor objectMode: true, (file, x, cb) ->
  @file = file
  @_through(cb)
  # cb null, file

module.exports.Through = Through =
class Through extends Base
  constructor: ->
    super()

  promise: ->
    __ = @
    return new Promise (resolve, reject) =>
      @on 'finish', ->
        resolve __
      @on 'error', reject

module.exports.Source =
class SourceStream extends Stream.Readable
  constructor: (@src, @opts)->
    super objectMode: true
    @file = new File(@src, @opts)

  _read: ->
    @push @file
    @push null

  promise: ->
    __ = @
    return new Promise (resolve, reject) =>
      resolve __
      @on 'error', reject


module.exports.Dest =
class DestStream extends Through
  id: 'dest'
  constructor: (@fs, @dst, @opts) ->
    super()

  _through: (cb) ->
    @fs.write @dst, @opts, @file.clone()
    # @file = @file.clone()
    @file.dst = @dst
    @file.dstOpts = @opts
    cb null, @file

module.exports.Writer =
class WriterStream extends Through
  id: 'writer'
  constructor: () ->
    super()
    @queue = []

  enqueue: (data) ->
    @queue.push data

  _through: (cb) ->
    @file.content = @file.content.concat @queue
    console.log "Writes #{@file.content}"
    cb null, @file

module.exports.Rename =
class RenameStream extends Through
  id: 'rename'

  constructor: (@newName) ->
    super()

  _through: (cb) ->
    @file.name = @newName
    cb null, @file

MERGE_COUNT = 0
module.exports.Merge =
class MergeStream extends Stream.Readable
  constructor: (@streams)->
    super objectMode: true
    @id = MERGE_COUNT++
    @file = new File("merged_#{@id}")

  _read: ->

    console.log "Merging"
    that = this
    Promise.reduce(@streams.map((s) ->
      if not s.promise?
        console.log s instanceof DestStream
        console.log s.constructor
        console.log s
      s.promise()), ((content, s) ->
        return content.concat s.file.content), [])
      .then((content) ->
        console.log(content)

        that.file.content = content
        that.push that.file
        that.push null
        )
  promise: ->
    __ = @
    return new Promise (resolve, reject) =>
      resolve __
      @on 'error', reject
