util = {check} = require('./util')

FS = require('./mock/fs')
File = require('./mock/file')
{Source, Dest, Writer, Merge} = require('./mock/stream')

FS.open('mock')

describe "Mock", ->
  describe "Stream", ->
    it "Creates source stream", ->
      s = new Source('src')
      check(s).for.src('src')
    it "Writes with WriterStream", ->
      w = new Writer()
      w.enqueue('foo')
      r = new Source('src1', {foo: 1})
        .pipe(w)

      r.promise().tap ->
        expect(r.id, "resulting stream should be last stream down the pipe").to.equal(w.id)
        check(r).for.src('src1', {foo: 1})
          .and.name('src1')
          .and.content(['foo'])
    it "Writes with multiple WriterStreams", ->
      w1 = new Writer()
      w1.enqueue('foo')
      w2 = new Writer()
      w2.enqueue('bar')
      r = new Source('src2', {foo: 1})
        .pipe(w1)
        .pipe(w2)

      r.promise().tap ->
        expect(r.id, "resulting stream should be last stream down the pipe").to.equal(w2.id)
        check(r).for.src('src2', {foo: 1})
          .and.name('src2')
          .and.content(['foo', 'bar'])
    it "Stores to FS via DestStream", ->
      w1 = new Writer()
      w1.enqueue('foo')
      w2 = new Writer()
      w2.enqueue('bar')
      d = new Dest(FS, 'dst3', {bar: 2})
      r = new Source('src3', {foo: 1})
        .pipe(w1)
        .pipe(w2)
        .pipe(d)

      r.promise().tap ->
        expect(r.id, "resulting stream should be last stream down the pipe").to.equal(d.id)
        check(r).for.src('src3', {foo: 1})
          .and.name('src3')
          .and.content(['foo', 'bar'])
          .and.dst('dst3', {bar: 2})
        util.checkFile('src3', 'dst3', ['foo', 'bar'], {bar: 2})
    it "Merges streams", ->
      w1 = new Writer()
      w1.enqueue('foo1')
      r1 = new Source('src.sub1', {foo: 1})
        .pipe(w1)
      w2 = new Writer()
      w2.enqueue('foo2')
      r2 = new Source('src.sub2', {foo: 2})
        .pipe(w2)

      m = new Merge([r1, r2])
      d = new Dest(FS, 'dst4', {bar: 2})

      r = m.pipe(d)

      r.promise().tap (d) ->
        expect(r.id, "resulting stream should be last stream down the pipe").to.equal(d.id)
        check(r).for.content(['foo1', 'foo2'])
        util.checkFile("merged_#{m.id}", 'dst4', ['foo1', 'foo2'], {bar: 2})



  describe "File", ->
    it "Clones", ->
      f1 = new File('s1', {foo: 1})
      f1.content.push('a')
      f2 = f1.clone()
      expect(f2.id, "file should have unique ID").not.to.equal(f1.id)
      f2.src = 's2'
      expect(f2.src, "file should have copied src").not.to.equal(f1.src)
      f2.srcOpts.foo = 2
      expect(f2.srcOpts, "file should have copied srcOpts").not.to.deep.equal(f1.srcOpts)
      f2.content.push('b')
      expect(f2.content, "file should have copied content").not.to.deep.equal(f1.content)
  describe "FS", ->
    it "Stores a copy of file", ->
      w1 = new Writer()
      w1.enqueue('foo')
      w2 = new Writer()
      w2.enqueue('bar')
      w3 = new Writer()
      w3.enqueue('zzz')
      d = new Dest(FS, 'dst4', {bar: 2})
      r = new Source('src4', {foo: 1})
        .pipe(w1)
        .pipe(w2)
        .pipe(d)
        .pipe(w3)

      r.promise().tap ->
        expect(r.id, "resulting stream should be last stream down the pipe").to.equal(w3.id)
        check(r).for.src('src4', {foo: 1})
          .and.name('src4')
          .and.content(['foo', 'bar', 'zzz'])
          .and.dst('dst4', {bar: 2})
        util.checkFile('src4', 'dst4', ['foo', 'bar'], {bar: 2})
