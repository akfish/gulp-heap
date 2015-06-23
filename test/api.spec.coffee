expect = require('chai').expect

util = {check} = require('./util')
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

  it ".source", ->
    s = a().source(src, srcOpts)()
    check(s).for.src(src, srcOpts)
    check(s).for.name(src)
    check(s).for.dst(undefined, undefined)
    check(s).for.content([a.raw.payload()])

  it ".dest", ->
    expectedContent = [a.raw.payload()]
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
    
    check(s).for.src(src, {})
    check(s).for.name(src)
    check(s).for.dst(dstThen, {})
    check(s).for.content(expectedContent)
    util.checkFile(src, dstThen, expectedContent, {})

  it ".with", ->
    dstW = dst + ".with"
    expectedContent = [
      a.raw.payload(),
      w.before.payload(),
      b.raw.payload(),
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


      check(s).for.src(src, {})
      check(s).for.name(src)
      check(s).for.dst(dstW, {})
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


      check(s).for.src(src, {})
      check(s).for.name(src)
      check(s).for.dst(dstW, {})
      check(s).for.content(expectedContent)
      util.checkFile(src, dstW, expectedContent, {})

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


      check(s).for.src(src, {})
      check(s).for.name(src)
      check(s).for.dst(dstW, {})
      check(s).for.content(expectedContent)
      util.checkFile(src, dstW_next, expectedContent)

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

      check(s).for.src(src, {})
      check(s).for.name(src)
      check(s).for.dst(dstIf, {})
      check(s).for.content(expectedContent)
      util.checkFile(src, dstIf, expectedContent, {})

    it "should work with wrapper", ->
      dstIf = dst + ".with.if"
      expectedContent = [
        a.raw.payload(),
        b.raw.payload(),
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

      check(s).for.src(src, {})
      check(s).for.name(src)
      check(s).for.dst(dstIf, {})
      check(s).for.content(expectedContent)
      util.checkFile(src, dstIf, expectedContent, {})

    it "should work with wrapper", ->
      dstIf = dst + ".with.ifNot"
      expectedContent = [
        a.raw.payload(),
        b.raw.payload(),
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
    expectedContent1 = [a.raw.payload()]

    s = a(src, dst1)
      .next(b())()
    util.checkFile(src, dst1, expectedContent1, {})
  it ".write", ->
    dst1 = dst + '.write.1'
    dst2 = dst + '.write.2'
    expectedContent1 = [a.raw.payload()]
    expectedContent2 = [a.raw.payload(), b.raw.payload()]

    s = a(src, dst1)
      .next(b()).write(dst2)()
    util.checkFile(src, dst1, expectedContent1, {})
    util.checkFile(src, dst2, expectedContent2, undefined)

  it ".rename", ->
    dstRename = dst + '.rename'
    newName = 'whatever'
    expectedContent = [a.raw.payload()]

    s = a(src, dstRename).rename(newName)()

    util.checkFile(newName, dstRename, expectedContent, {})
