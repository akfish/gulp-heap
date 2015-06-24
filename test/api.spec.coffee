expect = require('chai').expect

util = {check} = require('./util')
core = require('../lib/core')

{Stream, makeTask, FS} = require('./mock')

FS.open('api')

aRaw = makeTask('a')
bRaw = makeTask('b')
cRaw = makeTask('c')
dRaw = makeTask('d')
eRaw = makeTask('e')

a = core.task aRaw
b = core.task bRaw
c = core.task cRaw
d = core.task dRaw
e = core.task eRaw

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

  it ".source", ->
    s = a().source(src, srcOpts)()
    check(s).for.src(src, srcOpts)
    check(s).for.name(src)
    check(s).for.dst(undefined, undefined)
    check(s).for.content([aRaw.payload()])

  it ".dest", ->
    expectedContent = [aRaw.payload()]
    s = a().source(src, srcOpts).dest(dst, dstOpts)()
    check(s).for.src(src, srcOpts)
    check(s).for.name(src)
    check(s).for.dst(dst, dstOpts)
    check(s).for.content(expectedContent)
    util.checkFile(src, dst, expectedContent, dstOpts)

  it ".then", ->
    aOpts = { foo: 'a' }
    bOpts = { bar: 'b' }
    cOpts = "string"
    dOpts = ->
    expectedContent = [
      aRaw.payload(aOpts),
      bRaw.payload(bOpts),
      cRaw.payload(cOpts),
      dRaw.payload(dOpts),
      eRaw.payload(),
    ]
    dstThen =  dst + ".then"
    s = a(src, dstThen, aOpts)
      .then(b(bOpts))
      .then(c(cOpts))
      .then(d(dOpts))
      .then(e())()

    check(s).for.src(src, {})
    check(s).for.name(src)
    check(s).for.dst(dstThen, {})
    check(s).for.content(expectedContent)
    util.checkFile(src, dstThen, expectedContent, {})

  it ".with", ->
    dstW = dst + ".with"
    expectedContent = [
      aRaw.payload(),
      w.before.payload(),
      bRaw.payload(),
      w.after.payload()
    ]

    s = a(src, dstW).then(b()).with(w())()

    check(s).for.src(src, {})
    check(s).for.name(src)
    check(s).for.dst(dstW, {})
    check(s).for.content(expectedContent)
    util.checkFile(src, dstW, expectedContent, {})

  describe ".wrap", ->
    it "should work", ->
      dstW = dst + ".wrap"
      expectedContent = [
        aRaw.payload(),
        bRaw.payload(),
        w.before.payload(),
        cRaw.payload(),
        dRaw.payload(),
        w.after.payload()
      ]
      s = a(src, dstW)
        .then(b())
        .then(c())
        .then(d())
        .wrap(2).with(w())()


      check(s).for.src(src, {})
      check(s).for.name(src)
      check(s).for.dst(dstW, {})
      check(s).for.content(expectedContent)
      util.checkFile(src, dstW, expectedContent, {})

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
        aRaw.payload(),
        bRaw.payload(),
        w.before.payload(),
        cRaw.payload(),
        dRaw.payload(),
        w.after.payload()
      ]

      s = a(src, dstW)
        .then(b())
        .next(c())
        .then(d())
        .wrap(2).with(w())
        .write(dstW_next)()


      check(s).for.src(src, {})
      check(s).for.name(src)
      check(s).for.dst(dstW_next)
      check(s).for.content(expectedContent)
      util.checkFile(src, dstW_next, expectedContent)

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
        aRaw.payload(),
        bRaw.payload(),
        cRaw.payload(),
        dRaw.payload(),
        w.after.payload()
      ]
      s = a(src, dstW)
        .then(b())
        .then(c())
        .then(d())
        .wrapAll().with(w())()

      check(s).for.src(src, {})
      check(s).for.name(src)
      check(s).for.dst(dstW, {})
      check(s).for.content(expectedContent)
      util.checkFile(src, dstW, expectedContent, {})

    it "should not penetrate .next() call", ->
      dstW = dst + ".next.wrapAll"
      dstW_next = dst + ".next.wrapAll.1"
      expectedContent = [
        aRaw.payload(),
        bRaw.payload(),
        w.before.payload(),
        cRaw.payload(),
        dRaw.payload(),
        w.after.payload()
      ]
      s = a(src, dstW)
        .then(b())
        .next(c())
        .then(d())
        .wrapAll().with(w())
        .write(dstW_next)()


      check(s).for.src(src, {})
      check(s).for.name(src)
      check(s).for.dst(dstW_next)
      check(s).for.content(expectedContent)
      util.checkFile(src, dstW_next, expectedContent)

  describe ".if", ->
    it "should work with task", ->
      aOpts = { foo: 'a' }
      bOpts = { bar: 'b' }
      cOpts = "string"
      dOpts = ->
      expectedContent = [
        aRaw.payload(aOpts),
        bRaw.payload(bOpts),
        # cRaw.payload(cOpts),
        dRaw.payload(dOpts),
        eRaw.payload(),
      ]
      dstIf =  dst + ".if"
      s = a(src, dstIf, aOpts)
        .then(b(bOpts)).if(true)
        .then(c(cOpts)).if(false)
        .then(d(dOpts))
        .then(e())()

      check(s).for.src(src, {})
      check(s).for.name(src)
      check(s).for.dst(dstIf, {})
      check(s).for.content(expectedContent)
      util.checkFile(src, dstIf, expectedContent, {})

    it "should work with wrapper", ->
      dstIf = dst + ".with.if"
      expectedContent = [
        aRaw.payload(),
        bRaw.payload(),
      ]

      s = a(src, dstIf).then(b()).with(w()).if(false)()

      check(s).for.src(src, {})
      check(s).for.name(src)
      check(s).for.dst(dstIf, {})
      check(s).for.content(expectedContent)
      util.checkFile(src, dstIf, expectedContent, {})

  describe ".ifNot", ->
    it "should work with task", ->
      aOpts = { foo: 'a' }
      bOpts = { bar: 'b' }
      cOpts = "string"
      dOpts = ->
      expectedContent = [
        # aRaw.payload(aOpts),
        bRaw.payload(bOpts),
        # cRaw.payload(cOpts),
        dRaw.payload(dOpts),
        eRaw.payload(),
      ]
      dstIf =  dst + ".ifNot"
      s = a(src, dstIf, aOpts).ifNot(true)
        .then(b(bOpts)).ifNot(false)
        .then(c(cOpts)).ifNot(true)
        .then(d(dOpts))
        .then(e())()

      check(s).for.src(src, {})
      check(s).for.name(src)
      check(s).for.dst(dstIf, {})
      check(s).for.content(expectedContent)
      util.checkFile(src, dstIf, expectedContent, {})

    it "should work with wrapper", ->
      dstIf = dst + ".with.ifNot"
      expectedContent = [
        aRaw.payload(),
        bRaw.payload(),
      ]

      s = a(src, dstIf).then(b()).with(w()).ifNot(true)()

      check(s).for.src(src, {})
      check(s).for.name(src)
      check(s).for.dst(dstIf, {})
      check(s).for.content(expectedContent)
      util.checkFile(src, dstIf, expectedContent, {})

  it ".next", ->
    dst1 = dst + '.next.1'
    dst2 = dst + '.next.2'
    expectedContent1 = [aRaw.payload()]

    s = a(src, dst1)
      .next(b())()
    util.checkFile(src, dst1, expectedContent1, {})

  it ".write", ->
    dst1 = dst + '.write.1'
    dst2 = dst + '.write.2'
    expectedContent1 = [aRaw.payload()]
    expectedContent2 = [aRaw.payload(), bRaw.payload()]

    s = a(src, dst1)
      .next(b()).write(dst2)()

    check(s).for.src(src, {})
    check(s).for.dst(dst2)
    check(s).for.name(src);
    check(s).for.content(expectedContent2);
    util.checkFile(src, dst1, expectedContent1, {})
    util.checkFile(src, dst2, expectedContent2, undefined)

  it ".rename", ->
    dstRename = dst + '.rename'
    newName = 'whatever'
    expectedContent = [aRaw.payload()]

    s = a(src, dstRename).rename(newName)()

    util.checkFile(newName, dstRename, expectedContent, {})

  describe ".fork", ->
    multiple = core.task (stream, opts) ->
      # Note: sub-streams are created by their parent
      stream.A = new Stream(stream.src, stream.srcOpts)
      stream.B = new Stream(stream.src, stream.srcOpts)

      stream.A.write('>A')
      stream.B.write('>B')

      stream

    aContent = ['>A']
    bContent = ['>B']

    fullContent = bContent.concat(aContent)

    it "should work", ->
      src = "fork_src"
      dst = "frok_dst"
      dstA = "frok_dst_a"
      dstB = "frok_dst_b"
      s = multiple(src, dst)
        .fork("A").write(dstA).merge()
        .fork("B").write(dstB).merge()()

      check(s).for.src(src, {})
      check(s).for.dst(dst, {})
      check(s).for.name(src)
      check(s).for.content(fullContent)

      util.checkFile(src, dst, fullContent, {})
      util.checkFile(src, dstA, aContent)
      util.checkFile(src, dstB, bContent)

    it "should work with wrapper"
    it "should work with .wrap()"
    it "should work with .wrapAll()"
