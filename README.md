# gulp-heap

Modular gulp tasks.

(For my personal use only. No guarantees. Use it at your own risk.)

## Installation

```bash
$ npm install --save-dev gulp-task
```

## Tasks

### Coffee Script

#### Usage
```coffee
# Other dependencies
{coffee} = require 'gulp-heap'

# Other tasks

gulp.task.coffee 'coffee', coffee(src, dst, opts)
```

#### API

`coffee(source, destination, options)`

Options:

* `sourceMap` - generate source map, default = `true`

See also: [gulp-coffee](https://github.com/wearefractal/gulp-coffee#options)
