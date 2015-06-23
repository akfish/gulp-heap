var _ = require('underscore'),
  proxy = require('./proxy'),
  util = require('./util');

var TASK_COUNTER = 0;

function Selection() {
  this.from = this.to = -1;
}

Selection.prototype.clear = function() {
  this.from = this.to = -1;
};

Selection.prototype.isClear = function() {
  return this.from < 0;
};

Selection.prototype.selectRange = function(from, to) {
  this.from = from;
  this.to = to;
};

Selection.prototype.selectOne = function(index) {
  this.from = this.to = index;
};

Selection.prototype.select = function(index, count) {
  this.from = index;
  this.to = index + count - 1;
};

function Task(raw, defaultOpts) {
  this.raw = raw;
  this.src = this.dst = null;
  this.srcOpts = {};
  this.dstOpts = {};
  this.id = TASK_COUNTER++;
  this.defaultOpts = util.defaults({}, defaultOpts);

  this.toggled = true;
  this.handdled = false;

  this._last = null;

  this.sel = new Selection();
  this._wrapperMap = {
    begin: {},
    end: {}
  };

  // Linked list
  this.head = this;
  this.prevTask = this.nextTask = null;
  this.parent = null;
  this.children = [];
}

Task.prototype.getTail = function() {
  var current = this.head;
  while (current.nextTask) { current = current.nextTask; }
  return current;
};


Task.prototype.source = function(src, opts) {
  var target = this.head.getTail();
  if (_.isString(src)) {
    target.src = src;
  } else {
    opts = src;
  }
  target.srcOpts = _.defaults({}, opts);
  return this.head.getRunner();
};

Task.prototype.dest = function(dst, opts) {
  var target = this.head.getTail();
  if (_.isString(dst)) {
    target.dst = dst;
  } else {
    opts = dst;
  }
  target.dstOpts = _.defaults({}, opts);
  return this.head.getRunner();
};

Task.prototype.then = function(runner) {
  var task = runner.task;
  var target = this.head.getTail();
  task.head = this.head;
  task.parent = target;
  target.children.push(runner);
  target._last = task;

  return this.head.getRunner();
};

Task.prototype.next = function(runner) {
  var task = runner.task;
  var target = this.head.getTail();
  task.head = this.head;
  target.nextTask = task;
  task.prevTask = target;

  return this.head.getRunner();
};

Task.prototype.wrap = function(count) {
  var target = this.head.getTail(),
    sel = target.sel;

  // Include target itself
  var from = target.children.length + 1 - count;

  if (from < 0 || from > target.children.length) throw new RangeError("Wrap count out of range");

  sel.select(from, count);

  return this.head.getRunner();
};

Task.prototype.wrapAll = function() {
  var target = this.head.getTail(),
    sel = target.sel;

  sel.select(0, target.children.length + 1);

  return this.head.getRunner();
};

Task.prototype.with = function(wrapper) {
  var target = this.head.getTail(),
    sel = target.sel;
  if (sel.isClear()) sel.selectOne(target.children.length + 1 - 1);

  var map = target._wrapperMap;
  if (!map.begin[sel.from]) map.begin[sel.from] = [];
  map.begin[sel.from].unshift(wrapper); // LIFO
  if (!map.end[sel.to]) map.end[sel.to] = [];
  map.end[sel.to].push(wrapper);

  target._last = wrapper;

  sel.clear();
  return this.head.getRunner();
};

Task.prototype.if = function(condition) {
  var target = this.head.getTail(),
    last = target._last || target;

  last.toggled = condition;

  return this.head.getRunner();
};

Task.prototype.ifNot = function(condition) {
  var target = this.head.getTail(),
    last = target._last || target;

  last.toggled = !condition;

  return this.head.getRunner();
};

Task.prototype.write = function(dst, opts) {
  var target = this.head.getTail();
  var w = Task.make(function(stream, o) {
    return proxy.writeStream(o, opts);
  })(dst);

  return target.then(w);
};

Task.prototype.rename = function(opts) {
  var target = this.head.getTail();

  var r = Task.make(function(stream, o) {
    var s = proxy.renameStream(o);
    return s;
  })(opts);

  return target.then(r);
};

Task.prototype._runner = function(cb, stream, opts) {
  opts = _.defaults({}, opts);

  function pipe(s) {
    if (stream && stream != s) {
      stream = stream.pipe(s);
    } else {
      stream = s;
    }
  }

  function runWrapper(m, i, cb) {
    if (!m[i]) return;
    m[i].forEach(function (wrapper) {
      if (!wrapper.toggled) return;
      cb(wrapper);
    });
  }

  var wMap = this._wrapperMap;

  function wrapBefore(i) {
    runWrapper(wMap.begin, i, function(w) {
      var ws = w.begin.call(undefined, stream, w.beginOpts);
      pipe(ws);
    });
  }

  function wrapAfter(i) {
    runWrapper(wMap.end, i, function(w) {
      var ws = w.end.call(undefined, stream, w.endOpts);
      pipe(ws);
    });
  }

  // Initialize stream if needed and possible
  if (!stream && this.src) {
    stream = proxy.createStream(this.src, this.srcOpts);
  }

  // Run self
  if (this.toggled) {
    wrapBefore(0);
    var s = this.raw.call(this, stream, this.opts);
    pipe(s);
    wrapAfter(0);
  }

  // Run children
  this.children.forEach(function (runner, i) {
    // if (runner.task.toggled) {
      wrapBefore(i + 1);
      stream = runner(cb, stream, {noWrite: true});
      wrapAfter(i + 1);
      // pipe(s);
    // }
  }, this);


  // Write stream if needed and possible
  if (!opts.noWrite && _.isString(this.dst)) {
    var s = proxy.writeStream(this.dst, this.dstOpts);
    pipe(s);
  }

  // TODO: run nexts
  var _next = this.nextTask;
  while (_next) {
    stream = _next.getRunner()(cb, stream);
    _next = _next.nextTask;
  }

  return stream;
};

Task.prototype.makeRunner = function() {
  var src, dst, opts;
  switch (arguments.length) {
    case 1:
      opts = arguments[0];
      break;
    case 2:
      src = arguments[0];
      dst = arguments[1];
      break;
    case 3:
      src = arguments[0];
      dst = arguments[1];
      opts = arguments[2];
      break;
    default:
  }

  this.src = src;
  this.dst = dst;
  this.opts = util.defaults(this.defaultOpts, opts);
  this.toggled = true;

  if (!this.__runner) {
    this.__runner = this._runner.bind(this);
    this.__runner.task = this;

    var that = this;
    var API = _.reduce([
      'source',
      'dest',
      'then',
      'next',
      'wrap',
      'wrapAll',
      'with',
      'if',
      'ifNot',
      'write',
      'rename'
    ], function(api, key) {
      api[key] = that[key].bind(that);
      return api;
    }, {});

    _.extend(this.__runner, API);
  }

  return this.__runner;
};

Task.prototype.getRunner = function() {
  return this.__runner;
};

Task.make = function(raw, defaultOpts) {
  return function() {
    var task = new Task(raw, defaultOpts);
    return task.makeRunner.apply(task, arguments);
  };
};

module.exports = Task;