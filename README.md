# gulp-heap

[![Build Status](https://travis-ci.org/akfish/gulp-heap.svg?branch=master)](https://travis-ci.org/akfish/gulp-heap)

Semantic gulp API.

**Experimental and still under developing, not suitable for production use**

## A Quick Peek

```coffee
gulp = require 'gulp'
heap = {sourcemaps, cli} = require 'gulp-heap'
coffee = heap.require('gulp-coffee')
uglify = heap.require('gulp-uglify')
concat = heap.require('gulp-concat')

gulp.task 'coffee',
  coffee('./coffee/**/*.coffee', './lib/')
    .then(uglify())
    .wrapAll().with(sourcemaps()).if(cli.opts.debug)
    .next(concat('all.js')).write('./dist/')
```

The above gulp task does the following:
* Compile `./coffee/**/*.coffee` then write uglified versions to `./lib/`
* Generate source maps if `debug` CLI flag is set (runned with `gulp coffee --debug`)
* Then concat all `.js` files and write `all.js` to `./dist`

The equivalent code (without CLI arguments handling) in vanilla gulp API would be:

```coffee
gulp = require 'gulp'
gutil = require 'gutil'
plumber = require 'gulp-plumber'
coffee = require 'gulp-coffee'
uglify = require 'gulp-uglify'
concat = require 'gulp-concat'
sourcemaps = require 'gulp-sourcemaps'

gulp.task 'coffee', ->
  gulp.src('./coffee/**/*.coffee')
    .on('error', gutil.log)
    .pipe(plumber())
    .pipe(sourcemaps.init())
    .pipe(coffee())
    .pipe(uglify())
    .pipe(sourcemaps.write())
    .pipe(gulp.dest('./lib/'))
    .pipe(concat('all.js'))
    .pipe(gulp.dest('./dist/'))
```

## Installation

```bash
$ npm install --save-dev gulp-task
```

## The Patterns

Some patterns are observed in my time of using gulp.

### Task Life Cycle

```coffee
gulp.src(src)
  .on('error', gutil.log) # Error handling
  .pipe(plumber())        # Prevent pipe breaking
  .pipe(task(opts))
  # Other tasks
  .pipe(gulp.dest(dst))
  # Do other stuff
```

The first called `gulp-heap` through task would handle all of that with one line of code:

```coffee
task(src, dst, opts)
  .then(otherTask()) # Chained API
```

Sometimes options are needed for `gulp.src` or `gulp.dest` calls. The equivalent `gulp-heap` APIs are:

```coffee
task(opts).source(src, srcOpts).dest(dst, dstOpts)

# Useful when running mocha tests for example:
mocha(opts).source(testSrc, {read: false})
```

### Through Tasks

Tasks that are called once and connected with `.pipe` are called through tasks:

```coffee
file.pipe(task1()).pipe(task2())#...
```

They can be chained with `.then` or `.next` call:

```coffee
# task2 are executed before write to dst
task1(src, dst)
  .then(task2())
  # ...
# task2 are executed after write to dst
task2(src, dst)
  .next(task2())
  # ...
```

### Wrapper Tasks

Tasks that are called before and after another task are called wrapper tasks:

```coffee
file
  .pipe(wrapper.begin())
  .pipe(task())
  .pipe(wrapper.end())
```

A more cleaned syntax with `.with` method:
```coffee
task(src, dst).with(wrapper())
```

By default, the wrapper will wrap the one through task before it's called. Multiple tasks can be selected with `wrap` and `wrapAll` methods:

```coffee
# Wrap task1, task2, task3 with wrapper
task1(src, dst).then(task2()).then(task3()).wrapAll().with(wrapper())

# Wrap previous 2 tasks (task2, task3) with wrapper
task1(src, dst).then(task2()).then(task3()).wrap(2).with(wrapper())
```

Wrap methods cannot penetrate `next` call (the nearest `gulp.src` call):
```coffee
# Only wraps task3
task1(src, dst).then(task2()).next(task3()).wrapAll().with(wrapper())
# Throws a RangeError
task1(src, dst).then(task2()).next(task3()).wrap(2).with(wrapper())
```

### Conditional Tasks

Sometimes you will want to toggle some tasks with bool values (i.e from CLI):

```coffee
file = gulp.src(src)
if (debug)
  file = file.pipe(task1())
file.pipe(task2())
```

It gets messy with wrappers:

```coffee
file = gulp.src(src)
if (debug)
  file = file.pipe(wrapper.begin())
file.pipe(task2())
if (debug)
  file = file.pipe(wrapper.end())
```

Instead, try this:

```coffee
task(src, dst).then(task1()).if(debug)

task(src, dst).then(task2()).with(wrapper).if(debug)
```

## API

_See last section for most of the APIs_

- [ ] Better API docs

### Require Helper

Create through tasks or wrappers with vanilla gulp plugins:

```coffee
heap = require 'gulp-heap'
coffee = heap.require('gulp-coffee')
sourcemaps = heap.require('gulp-sourcemaps').asWrapper('init', 'write')

# Initiate a task
coffee(src, dst, opts)

# As a through task
otherTask(src, dst)
  .then(coffee(opts)) # src, dst are omitted
  .with(sourcemaps())
```

### Convertor

Some gulp plugin modules like `gulp-csslint` exports in multiple fields and cannot be required directly. They can be converted by:

```coffee
heap = require 'gulp-heap'
# Require directly
csslint = require('gulp-csslint')
# Then convert
lint      = heap.convert(csslint).toTask()
reporter  = heap.convert(csslint.reporter).toTask()
```

Current limitations:
* The plugin should only take one arguments


## Recipes

### Browserify

Direct translation from [Gulp Recipes | Browserify + Transforms](https://github.com/gulpjs/gulp/blob/master/docs/recipes/browserify-transforms.md):

```coffee
source = heap.require('vinyl-source-stream')
buffer = heap.require('vinyl-buffer')
uglify = heap.require('gulp-uglify')
browserify = heap.convert((opts) -> require('browserify')(opts).bundle()).toTask()

gulp.task 'browser',
  browserify(browserifyOpts)
    .then(source('app.js'))
    .then(buffer()).dest(dist)
    .next(uglify())
    .rename('app.min.js')
    .write(dist)
```
