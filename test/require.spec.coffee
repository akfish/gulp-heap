expect = require('chai').expect

_require = require('../lib/require')

util = {check} = require('./util')
path = require('path')

{Stream, makeTask, FS} = require('./mock')

FS.open('require')

describe "Require", ->
  rawTask = require('./raw-task')
  rawWrapper = require('./raw-wrapper')
  taskMaker = null
  it "should require module as task", ->
    src = 'src_path'
    dst = 'dst_path'

    expectedContent = [rawTask.payload()]

    taskMaker = _require(path.resolve(__dirname, './raw-task'))
    expect(taskMaker).to.be.a('function')
    task = taskMaker(src, dst)
    expect(task).to.be.a('function')
      .that.has.property('hasContext')
      .that.is.true

    s = task()

    check(s).for.src(src, {})
    check(s).for.dst(dst, {})
    check(s).for.name(src)
    check(s).for.content(expectedContent)

    util.checkFile(src, dst, expectedContent, {})

  it "should require module as wrapper", ->
    wrapperMaker = _require(path.resolve(__dirname, './raw-wrapper')).asWrapper('before', 'after')
    expect(wrapperMaker).to.be.a('function')

    wrapper = wrapperMaker()

    expect(wrapper).to.have.property('isWrapper')
      .that.is.true

    expectedContent = [
      rawWrapper.before.payload()
      rawTask.payload()
      rawWrapper.after.payload()
    ]

    src = 'src_path.wrapped'
    dst = 'dst_path.wrapped'

    s = taskMaker(src, dst).with(wrapper)()

    check(s).for.src(src, {})
    check(s).for.dst(dst, {})
    check(s).for.name(src)
    check(s).for.content(expectedContent)

    util.checkFile(src, dst, expectedContent, {})
