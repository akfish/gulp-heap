expect = require('chai').expect
{FS} = require('./mock')

module.exports = utils =
  checkSrc: (s, src, opts) ->
    expect(s).to.have.a.property('src')
      .that.equals(src)
    expect(s).to.have.a.property('srcOpts')
      .that.to.deep.equals(opts)

  checkDst: (s, dst, opts) ->
    expect(s).to.have.a.property('dst')
      .that.equals(dst)
    expect(s).to.have.a.property('dstOpts')
      .that.to.deep.equals(opts)

  checkName: (s, name) ->
    expect(s).to.have.a.property('name')
      .that.equals(name)

  checkContent: (s, content) ->
    expect(s).to.have.a.property('content')
      .that.deep.equals(content)

  checkFile: (name, dst, content, opts) ->
    file = FS.read(dst)

    expect(file).not.to.be.null
    expect(file.name).to.deep.equals(name)
    expect(file.content).to.deep.equals(content)
    expect(file.opts).to.deep.equals(opts)
