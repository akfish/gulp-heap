expect = require('chai').expect

util = require('./util')
core = require('../lib/core')

{Stream, makeTask, FS} = require('./mock')

FS.open('task')

describe 'Task', ->
  task = null
  taskOpts =
    foo: 1
  mockTask = makeTask('foo')
  expectedContent = [mockTask.payload(taskOpts)]

  it "can be made", ->
    task = core.task mockTask
    expect(task).to.be.a('function')

  it "should initialize fully", ->
    src = 'src_path'
    dst = 'dst_path'
    s = task(src, dst, taskOpts)()
    expect(s).to.be.an.instanceOf(Stream)
    util.checkSrc(s, src, {})
    util.checkDst(s, dst, {})
    util.checkName(s, src)
    util.checkContent(s, expectedContent)

    util.checkFile(src, dst, expectedContent, {})

  it "should initialize partially", ->
    src = 'upstream_src'
    upstreamOpts = foo: 'upstream'
    upstream = new Stream(src, upstreamOpts)
    s = task(taskOpts)(null, upstream)
    expect(s).to.be.an.instanceOf(Stream)
    util.checkSrc(s, src, upstreamOpts)
    util.checkDst(s)
    util.checkName(s, src)
    util.checkContent(s, expectedContent)
