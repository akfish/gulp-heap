File = require('./file')
Promise = require('bluebird')
cap = require('chai-as-promised')

module.exports = (chai, utils) ->
  resolveFile = (p, cb) ->
    expect(p).to.be.instanceof(Promise)
    p.then (stream) ->
      expect(stream, 'stream should have file').to.have.property('file')
        .that.is.an.instanceof(File)

      cb stream.file
      return stream.file

    p

  Assertion.addMethod 'file', (src) ->
    p = resolveFile this._obj, (file) =>
      this.assert(
        file.src == src,
        "expect file.src == #{src}",
        "expect file.src != #{src}",
        src,
        file.src
      )

    cap.transferPromiseness @, p

  Assertion.addMethod 'name', (name) ->
    p = resolveFile this._obj, (file) =>
      this.assert(
        file.name == name,
        "expect file.name == #{name}",
        "expect file.name != #{name}",
        name,
        file.name
      )
    cap.transferPromiseness @, p
