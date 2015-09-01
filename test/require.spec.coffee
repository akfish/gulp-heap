expect = require('chai').expect

heap_require = require('../lib/require')
Task = require('../lib/task')

util = {check} = require('./util')
path = require('path')

FS = require('./mock/fs')
FS.open('require')

describe "Require", ->
  rawTask = require('./mock/task')
  rawWrapper = require('./mock/wrapper')
  taskMaker = null
  it "should require module as task", ->
    src = 'src_path'
    dst = 'dst_path'

    expectedContent = [rawTask.payload()]

    taskMaker = heap_require(path.resolve(__dirname, './mock/task'))
    expect(taskMaker).to.be.a('function')
    task = taskMaker(src, dst)
    expect(task).to.be.a('function')
      .that.has.property('task')
      .that.is.instanceOf(Task)

    s = task()

    s.promise().tap (s) ->
      check(s).for.src(src, {})
      check(s).for.dst(dst, {})
      check(s).for.name(src)
      check(s).for.content(expectedContent)

      util.checkFile(src, dst, expectedContent, {})

  it "should require module as wrapper", ->
    wrapperMaker = heap_require(path.resolve(__dirname, './mock/wrapper')).asWrapper('before', 'after')
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

    s.promise().tap (s) ->
      check(s).for.src(src, {})
      check(s).for.dst(dst, {})
      check(s).for.name(src)
      check(s).for.content(expectedContent)

      util.checkFile(src, dst, expectedContent, {})
