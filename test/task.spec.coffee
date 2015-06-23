expect = require('chai').expect

util = {check} = require('./util')
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
    check(s).for.src(src, {})
    check(s).for.dst(dst, {})
    check(s).for.name(src)
    check(s).for.content(expectedContent)

    util.checkFile(src, dst, expectedContent, {})

  it "should initialize partially", ->
    src = 'upstream_src'
    upstreamOpts = foo: 'upstream'
    upstream = new Stream(src, upstreamOpts)
    s = task(taskOpts)(null, upstream)
    check(s).for.src(src, upstreamOpts)
    check(s).for.dst()
    check(s).for.name(src)
    check(s).for.content(expectedContent)
