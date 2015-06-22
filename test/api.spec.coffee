expect = require('chai').expect

core = require('../lib/core')

{Stream, makeTask, FS} = require('./mock')

FS.open('api')

raw = [

]

a = core.task makeTask('a')
b = core.task makeTask('b')
c = core.task makeTask('c')
d = core.task makeTask('d')
e = core.task makeTask('e')

describe 'API', ->
  src = 'a_source_src'
  srcOpts = { it: 'a' }
  dst = 'a_source_dst'
  dstOpts = { it: 'a' }

  checkSrc = (s, src, opts) ->
    expect(s).to.have.a.property('src')
      .that.equals(src)
    expect(s).to.have.a.property('srcOpts')
      .that.to.deep.equals(opts)

  checkDst = (s, dst, opts) ->
    expect(s).to.have.a.property('dst')
      .that.equals(dst)
    expect(s).to.have.a.property('dstOpts')
      .that.to.deep.equals(opts)

  checkName = (s, name) ->
    expect(s).to.have.a.property('name')
      .that.equals(name)

  checkContent = (s, content) ->
    expect(s).to.have.a.property('content')
      .that.deep.equals(content)

  checkFile = (name, dst, content, opts) ->
    file = FS.read(dst)

    expect(file).not.to.be.null
    expect(file.name).to.deep.equals(name)
    expect(file.content).to.deep.equals(content)
    expect(file.opts).to.deep.equals(opts)


  it ".source", ->
    s = a().source(src, srcOpts)()
    expect(s).to.be.an.instanceOf(Stream)
    checkSrc(s, src, srcOpts)
    checkName(s, src)
    checkDst(s, undefined, undefined)
    checkContent(s, [a.raw.payload()])

  it ".dest", ->
    expectedContent = [a.raw.payload()]
    s = a().source(src, srcOpts).dest(dst, dstOpts)()
    expect(s).to.be.an.instanceOf(Stream)
    checkSrc(s, src, srcOpts)
    checkName(s, src)
    checkDst(s, dst, dstOpts)
    checkContent(s, expectedContent)
    checkFile(src, dst, expectedContent, dstOpts)

  it ".then", ->
    aOpts = { foo: 'a' }
    bOpts = { bar: 'b' }
    cOpts = "string"
    dOpts = ->
    expectedContent = [
      a.raw.payload(aOpts),
      b.raw.payload(bOpts),
      c.raw.payload(cOpts),
      d.raw.payload(dOpts),
      e.raw.payload(),
    ]
    dstThen =  dst + ".then"
    s = a(src, dstThen, aOpts)
      .then(b(bOpts))
      .then(c(cOpts))
      .then(d(dOpts))
      .then(e())()
    expect(s).to.be.an.instanceOf(Stream)
    checkSrc(s, src, {})
    checkName(s, src)
    checkDst(s, dstThen, {})
    checkContent(s, expectedContent)
    checkFile(src, dstThen, expectedContent, {})

  it ".with"
  it ".wrap"
  it ".wrapAll"
  it ".next", ->
    dst1 = dst + '.next.1'
    dst2 = dst + '.next.2'
    expectedContent1 = [a.raw.payload()]

    s = a(src, dst1)
      .next(b())()
    checkFile(src, dst1, expectedContent1, {})
  it ".write", ->
    dst1 = dst + '.write.1'
    dst2 = dst + '.write.2'
    expectedContent1 = [a.raw.payload()]
    expectedContent2 = [a.raw.payload(), b.raw.payload()]

    s = a(src, dst1)
      .next(b()).write(dst2)()
    checkFile(src, dst1, expectedContent1, {})
    checkFile(src, dst2, expectedContent2, undefined)

  it ".rename", ->
    dstRename = dst + '.rename'
    newName = 'whatever'
    expectedContent = [a.raw.payload()]

    s = a(src, dstRename).rename(newName)()

    checkFile(newName, dstRename, expectedContent, {})
