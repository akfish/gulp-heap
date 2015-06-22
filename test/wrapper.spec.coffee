expect = require('chai').expect

core = require('../lib/core')

{Stream, makeTask, FS} = require('./mock')

FS.open('wrapper')

describe "Wrapper", ->
  it "can be made", ->
    before = makeTask("w:before")
    after = makeTask("w:after")
    wrapper = core.wrapper before, after
    expect(wrapper).to.be.a('function')
    made = wrapper()
    expect(made).to.deep.equals({
      isWrapper: true,
      toggled: true,
      beginOpts: {},
      endOpts: {},
      begin: before,
      end: after
    })
