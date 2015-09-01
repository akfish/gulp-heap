expect = require('chai').expect

core = require('../lib/core')
Wrapper = require('../lib/wrapper')

makeTask = require('./mock/task')

FS = require('./mock/fs')
FS.open('wrapper')

describe "Wrapper", ->
  it "can be made", ->
    before = makeTask("w:before")
    after = makeTask("w:after")
    wrapper = core.wrapper before, after
    expect(wrapper).to.be.a('function')
    made = wrapper()
    expect(made).to.be.instanceOf(Wrapper)
    expect(made).to.deep.equals({
      isWrapper: true,
      toggled: true,
      beginOpts: {},
      endOpts: {},
      begin: before,
      end: after
    })
