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

wBefore = makeTask('w:before')
wAfter = makeTask('w:after')
w = core.wrapper wBefore, wAfter
w.before = wBefore
w.after = wAfter

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

  it ".with", ->
    dstW = dst + ".with"
    expectedContent = [
      a.raw.payload(),
      w.before.payload(),
      b.raw.payload(),
      w.after.payload()
    ]

    s = a(src, dstW).then(b()).with(w())()
    expect(s).to.be.an.instanceOf(Stream)
    checkSrc(s, src, {})
    checkName(s, src)
    checkDst(s, dstW, {})
    checkContent(s, expectedContent)
    checkFile(src, dstW, expectedContent, {})

  describe ".wrap", ->
    it "should work", ->
      dstW = dst + ".wrap"
      expectedContent = [
        a.raw.payload(),
        b.raw.payload(),
        w.before.payload(),
        c.raw.payload(),
        d.raw.payload(),
        w.after.payload()
      ]
      s = a(src, dstW)
        .then(b())
        .then(c())
        .then(d())
        .wrap(2).with(w())()

      expect(s).to.be.an.instanceOf(Stream)
      checkSrc(s, src, {})
      checkName(s, src)
      checkDst(s, dstW, {})
      checkContent(s, expectedContent)
      checkFile(src, dstW, expectedContent, {})

    it "should not allow out of range value", ->
      makeWrongWrapping = ->
        a(src, dst)
          .then(b())
          .then(c())
          .then(d())
          .wrap(10).with(w())

      expect(makeWrongWrapping).to.throw(RangeError, "Wrap count out of range")

    it "should not penetrate .next() call", ->
      dstW = dst + ".next.wrap"
      dstW_next = dst + ".next.wrap.1"
      expectedContent = [
        a.raw.payload(),
        b.raw.payload(),
        w.before.payload(),
        c.raw.payload(),
        d.raw.payload(),
        w.after.payload()
      ]

      s = a(src, dstW)
        .then(b())
        .next(c())
        .then(d())
        .wrap(2).with(w())
        .write(dstW_next)()

      expect(s).to.be.an.instanceOf(Stream)
      checkSrc(s, src, {})
      checkName(s, src)
      checkDst(s, dstW, {})
      checkContent(s, expectedContent)
      checkFile(src, dstW_next, expectedContent)

      tryPenetrateNext = ->
        a(src, dst)
          .then(b())
          .next(c())
          .then(d())
          .wrap(3) # try to wrap b, c, d
          .with(w())
      expect(tryPenetrateNext).to.throw(RangeError, "Wrap count out of range")


  describe ".wrapAll", ->
    it "should work", ->
      dstW = dst + ".wrapAll"
      expectedContent = [
        w.before.payload(),
        a.raw.payload(),
        b.raw.payload(),
        c.raw.payload(),
        d.raw.payload(),
        w.after.payload()
      ]
      s = a(src, dstW)
        .then(b())
        .then(c())
        .then(d())
        .wrapAll().with(w())()

      expect(s).to.be.an.instanceOf(Stream)
      checkSrc(s, src, {})
      checkName(s, src)
      checkDst(s, dstW, {})
      checkContent(s, expectedContent)
      checkFile(src, dstW, expectedContent, {})

    it "should not penetrate .next() call", ->
      dstW = dst + ".next.wrapAll"
      dstW_next = dst + ".next.wrapAll.1"
      expectedContent = [
        a.raw.payload(),
        b.raw.payload(),
        w.before.payload(),
        c.raw.payload(),
        d.raw.payload(),
        w.after.payload()
      ]
      s = a(src, dstW)
        .then(b())
        .next(c())
        .then(d())
        .wrapAll().with(w())
        .write(dstW_next)()

      expect(s).to.be.an.instanceOf(Stream)
      checkSrc(s, src, {})
      checkName(s, src)
      checkDst(s, dstW, {})
      checkContent(s, expectedContent)
      checkFile(src, dstW_next, expectedContent)

  describe ".if", ->
    it "should work with task", ->
      aOpts = { foo: 'a' }
      bOpts = { bar: 'b' }
      cOpts = "string"
      dOpts = ->
      expectedContent = [
        a.raw.payload(aOpts),
        b.raw.payload(bOpts),
        # c.raw.payload(cOpts),
        d.raw.payload(dOpts),
        e.raw.payload(),
      ]
      dstIf =  dst + ".if"
      s = a(src, dstIf, aOpts)
        .then(b(bOpts)).if(true)
        .then(c(cOpts)).if(false)
        .then(d(dOpts))
        .then(e())()
      expect(s).to.be.an.instanceOf(Stream)
      checkSrc(s, src, {})
      checkName(s, src)
      checkDst(s, dstIf, {})
      checkContent(s, expectedContent)
      checkFile(src, dstIf, expectedContent, {})

    it "should work with wrapper", ->
      dstIf = dst + ".with.if"
      expectedContent = [
        a.raw.payload(),
        b.raw.payload(),
      ]

      s = a(src, dstIf).then(b()).with(w()).if(false)()
      expect(s).to.be.an.instanceOf(Stream)
      checkSrc(s, src, {})
      checkName(s, src)
      checkDst(s, dstIf, {})
      checkContent(s, expectedContent)
      checkFile(src, dstIf, expectedContent, {})

  describe ".ifNot", ->
    it "should work with task", ->
      aOpts = { foo: 'a' }
      bOpts = { bar: 'b' }
      cOpts = "string"
      dOpts = ->
      expectedContent = [
        a.raw.payload(aOpts),
        b.raw.payload(bOpts),
        # c.raw.payload(cOpts),
        d.raw.payload(dOpts),
        e.raw.payload(),
      ]
      dstIf =  dst + ".ifNot"
      s = a(src, dstIf, aOpts)
        .then(b(bOpts)).ifNot(false)
        .then(c(cOpts)).ifNot(true)
        .then(d(dOpts))
        .then(e())()
      expect(s).to.be.an.instanceOf(Stream)
      checkSrc(s, src, {})
      checkName(s, src)
      checkDst(s, dstIf, {})
      checkContent(s, expectedContent)
      checkFile(src, dstIf, expectedContent, {})

    it "should work with wrapper", ->
      dstIf = dst + ".with.ifNot"
      expectedContent = [
        a.raw.payload(),
        b.raw.payload(),
      ]

      s = a(src, dstIf).then(b()).with(w()).ifNot(true)()
      expect(s).to.be.an.instanceOf(Stream)
      checkSrc(s, src, {})
      checkName(s, src)
      checkDst(s, dstIf, {})
      checkContent(s, expectedContent)
      checkFile(src, dstIf, expectedContent, {})

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
