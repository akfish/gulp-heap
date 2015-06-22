expect = require('chai').expect

core = require('../lib/core')

{Stream, makeTask} = require('./mock')

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
    s = task('src_path', 'dst_path', taskOpts)()
    expect(s).to.be.an.instanceOf(Stream)
    expect(s).to.have.a.property('src')
      .that.equals('src_path')
    expect(s).to.have.a.property('srcOpts')
      .that.to.deep.equals({})
    expect(s).to.have.a.property('dst')
      .that.equals('dst_path')
    expect(s).to.have.a.property('dstOpts')
      .that.to.deep.equals({})
    expect(s).to.have.a.property('name')
      .that.equals('src_path')
    expect(s).to.have.a.property('content')
      .that.deep.equals(expectedContent)

  it "should initialize partially", ->
    upstreamOpts = foo: 'upstream'
    upstream = new Stream('upstream_src', upstreamOpts)
    s = task(taskOpts)(null, upstream)
    expect(s).to.be.an.instanceOf(Stream)
    expect(s).to.have.a.property('src')
      .that.equals('upstream_src')
    expect(s).to.have.a.property('srcOpts')
      .that.to.deep.equals(upstreamOpts)
    expect(s).to.have.a.property('dst')
      .that.to.be.undefined
    expect(s).to.have.a.property('dstOpts')
      .that.to.be.undefined
    expect(s).to.have.a.property('name')
      .that.equals('upstream_src')
    expect(s).to.have.a.property('content')
      .that.deep.equals(expectedContent)
