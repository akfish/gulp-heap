fs = require './fs'

mockProxy =
  createStream: (src, opts) ->
    fs.createReadStream(src, opts)

  renameStream: (name) ->
    fs.createRenameStream(name)

  writeStream: (dst, opts) ->
    fs.createWriteStream(dst, opts)

  mergeStreams: (streams) ->
    fs.createMergeStream(streams)

require('../../lib/proxy').init(mockProxy)
