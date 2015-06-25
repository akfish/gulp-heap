expect = require('chai').expect

util = {check} = require('./util')
core = require('../lib/core')

# {Stream, makeTask, FS} = require('./mock')
FS = require('./mock/fs')
{Writer} = require('./mock/stream')
FS.open('api')

makeTask = (name) ->
  raw = (stream, opts) ->
    sw = new Writer()
    payload =
      source: name
      opts: opts

    sw.enqueue(payload)

    sw

  raw.payload = (opts = {}) ->
    payload =
      source: name
      opts: opts
    payload

  raw.taskName = name

  raw
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
      .promise()
      .tap (s) ->
        check(s).for.src(src, srcOpts)
          .and.name(src)
          .and.content([aRaw.payload()])

  it ".dest", ->
    expectedContent = [aRaw.payload()]
    s = a().source(src, srcOpts).dest(dst, dstOpts)()
      .promise()
      .tap (s) ->
        check(s).for.src(src, srcOpts)
          .and.name(src)
          .and.dst(dst, dstOpts)
          .and.content(expectedContent)
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
      .promise()
      .tap (s) ->
        check(s).for.src(src, {})
          .and.name(src)
          .and.dst(dstThen, {})
          .and.content(expectedContent)
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
      .promise()
      .tap (s) ->
        check(s).for.src(src, {})
          .and.name(src)
          .and.dst(dstW, {})
          .and.content(expectedContent)
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
        .promise()
        .tap (s) ->
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
        .promise()
        .tap (s) ->
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
        .promise()
        .tap (s) ->
          check(s).for.src(src, {})
            .and.name(src)
            .and.dst(dstW, {})
            .and.content(expectedContent)
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
        .promise()
        .tap (s) ->
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
        .promise().tap (s) ->

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
        .promise().tap (s) ->

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
        .promise().tap (s) ->

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
        .promise().tap (s) ->

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
      .promise()
      .tap (s) ->
        util.checkFile(src, dst1, expectedContent1, {})


  it ".write", ->
    dst1 = dst + '.write.1'
    dst2 = dst + '.write.2'
    expectedContent1 = [aRaw.payload()]
    expectedContent2 = [aRaw.payload(), bRaw.payload()]

    s = a(src, dst1)
      .next(b()).write(dst2)()
      .promise().tap (s) ->
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
      .promise().tap (s) ->
        util.checkFile(newName, dstRename, expectedContent, {})

  describe ".fork", ->
    multipleRaw = (stream, opts) ->
      sw = new Writer()
      payload =
        source: "main"
        opts: opts

      sw.enqueue(payload)

      Object.defineProperty stream, 'A',
        get: ->
          console.log "Getting .A"
          sa = new Writer()
          pa =
            source: "A"

          sa.enqueue(pa)

          sw.pipe(sa)

      Object.defineProperty stream, 'B',
        get: ->
          console.log "Getting .B"
          sb = new Writer()
          pb =
            source: "B"

          sb.enqueue(pb)

          sw.pipe(sb)

      sw

    multipleRaw.taskName = "multiple"

    multiple = core.task multipleRaw

    mainContent = [source: 'main']

    aContent = mainContent.concat([source: 'A'])
    bContent = mainContent.concat([source: 'B'])

    fullContent = mainContent.concat(aContent).concat(bContent)

    it "should work", ->
      src = "fork_src"
      dst = "fork_dst"
      dstA = "fork_dst_a"
      dstB = "fork_dst_b"
      s = multiple(src, dst)
        .fork("A").write(dstA).merge()
        .fork("B").write(dstB).merge()()

      s.promise().tap (s) ->
        check(s).for.src(src, {})
        check(s).for.dst(dst, {})
        check(s).for.name(src)
        check(s).for.content(fullContent)

        util.checkFile(src, dst, fullContent, {})
        util.checkFile(src, dstA, aContent)
        util.checkFile(src, dstB, bContent)

    it "should work with wrapper"#, ->
      # src = "fork_src"
      # dst = "fork_dst_with"
      # dstA = "fork_dst_with_a"
      # dstB = "fork_dst_with_b"
      #
      # s = a(src, dst)
      #   .then(b())
      #   .then(multiple())
      #   .fork("A").write(dstA).merge()


    it "should work with .wrap()"
    it "should work with .wrapAll()"
