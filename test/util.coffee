expect = require('chai').expect
# {Stream, FS} = require('./mock')
FS = require('./mock/fs')
File = require('./mock/file')


module.exports = utils =
  checkSrc: (s, src, opts) ->
    expect(s, 'file.src').to.have.a.property('src')
      .that.equals(src)
    expect(s, 'file.srcOpts').to.have.a.property('srcOpts')
      .that.to.deep.equals(opts)
    @

  checkDst: (s, dst, opts) ->
    expect(s, 'file.dst').to.have.a.property('dst')
      .that.equals(dst)
    expect(s, 'file.dstOpts').to.have.a.property('dstOpts')
      .that.to.deep.equals(opts)
    @

  checkName: (s, name) ->
    expect(s, 'file.name').to.have.a.property('name')
      .that.equals(name)
    @

  checkContent: (s, content) ->
    expect(s, 'file.content').to.have.a.property('content')
      .that.deep.equals(content)
    @

  checkFile: (name, dst, content, opts) ->
    blob = FS.read(dst)
    file = blob.file
    expect(file).to.be.instanceof(File)

    expect(file, 'file').not.to.be.null
    expect(file.name, 'file.name').to.deep.equals(name)
    expect(file.content, 'file.content').to.deep.equals(content)
    expect(blob.opts, 'blob.opts').to.deep.equals(opts)

CHECKER_CACHE = {}

module.exports.check = (stream) ->
  if CHECKER_CACHE[stream.id]?
    return CHECKER_CACHE[stream.id]
  # expect(stream).to.be.an.instanceOf(Stream)
  expect(stream).to.have.property("file")

  file = stream.file

  if file.id of CHECKER_CACHE
    return CHECKER_CACHE[file.id]

  checker = {}

  checker.for = checker.and =
    src: utils.checkSrc.bind(checker, file)
    dst: utils.checkDst.bind(checker, file)
    name: utils.checkName.bind(checker, file)
    content: utils.checkContent.bind(checker, file)

  CHECKER_CACHE[file.id] = checker

  return checker
