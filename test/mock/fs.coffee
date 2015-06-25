_ = require('underscore')
{Source, Dest, Rename, Merge} = require('./stream')

class MockFS
  constructor: ->
    @_storage = {}

  open: (ns) ->
  #   if not @_storage[ns]?
  #     @_storage[ns] = {}
  #   @_currentNs = ns

  _getCurrentNs: ->
    # if not @_currentNs? then throw new Error("MockFS.ns not set")
    # return @_storage[@_currentNs]
    return @_storage

  write: (dst, opts, file) ->
    ns = @_getCurrentNs()

    copied = file.clone()

    ns[dst] =
      file: file
      opts: opts

  read: (dst) ->
    ns = @_getCurrentNs()

    ns[dst]

  createReadStream: (src, opts) ->
    return new Source(src, opts)

  createWriteStream: (dst, opts) ->
    return new Dest(@, dst, opts)

  createRenameStream: (name) ->
    return new Rename(name)

  createMergeStream: (streams) ->
    return new Merge(streams)


fs = new MockFS()

module.exports = fs
