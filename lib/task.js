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
  return this.to < 0;
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

  this.forks = {};
}

Task.prototype.getTail = function() {
  var current = this.head;
  while (current.nextTask) { current = current.nextTask; }
  return current;
};


Task.prototype.source = function(src, opts) {
  var target = this.head.getTail();
  if (_.isString(src) || _.isArray(src)) {
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

  if (from > target.children.length) throw new RangeError("Wrap count out of range");
  if (from < 0) {
    var forkParent = target.forkParent;
    if (!forkParent || -from > forkParent.children.length) {
      throw new RangeError("Wrap count out of range");
    }
  }

  sel.select(from, count);

  return this.head.getRunner();
};

Task.prototype.wrapAll = function() {
  var target = this.head.getTail(),
    sel = target.sel;

  var forkParent = target.forkParent,
    from = 0;

  if (forkParent) {
    from = -forkParent.children.length;
  }

  sel.select(from, target.children.length + 1);

  return this.head.getRunner();
};

Task.prototype._registerWrapperBegin = function(wrapper, i) {
  var map = this._wrapperMap;
  if (i < 0) i += this.children.length;
  if (!map.begin[i]) map.begin[i] = [];
  map.begin[i].unshift(wrapper); // LIFO
};

Task.prototype._registerWrapperEnd = function(wrapper, i) {
  var map = this._wrapperMap;
  if (i < 0) i += this.children.length;
  if (!map.end[i]) map.end[i] = [];
  map.end[i].push(wrapper); // LIFO
};

Task.prototype.with = function(wrapper) {
  var target, beginTarget, sel;
  target = beginTarget = this.head.getTail();
  sel = target.sel;
  if (sel.isClear()) sel.selectOne(target.children.length + 1 - 1);

  if (sel.from < 0) {
    forkParent = this.head.forkParent;
    if (!forkParent || -sel.from > forkParent.children.length) {
      throw new RangeError("Wrap count out of range");
    }
    beginTarget = forkParent;
  }
  target._registerWrapperBegin(wrapper, sel.from);
  target._registerWrapperEnd(wrapper, sel.to);

  // var map = target._wrapperMap;
  // if (!map.begin[sel.from]) map.begin[sel.from] = [];
  // map.begin[sel.from].unshift(wrapper); // LIFO
  // if (!map.end[sel.to]) map.end[sel.to] = [];
  // map.end[sel.to].push(wrapper);

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

Task.prototype._forkFrom = function(parent) {
  _.extend(this.__runner, {
    merge: this.merge.bind(this)
  });
  this.forkParent = parent;
};

Task.prototype._forkTo = function(runner) {
  var forkPoint = this.children.length;
  if (!this.forks[forkPoint]) this.forks[forkPoint] = [];
  this.forks[forkPoint].push(runner);
  runner.task._forkFrom(this);
};

Task.prototype.fork = function(name) {
  var target = this.head.getTail();

  // Make an empty task for chaining
  var m = Task.make()();
  m._toFork = name;

  target._forkTo(m);

  // Consequent operations are performed on the forked task
  // Util .merge() is called
  return m;
};

Task.prototype.merge = function() {
  // Nothing is performed at run-time
  // Return to the point before merge
  return this.forkParent.getRunner();
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

  function runWrapper(m, i, c) {
    if (!m[i]) return;
    m[i].forEach(function (wrapper) {
      if (!wrapper.toggled) return;
      c(wrapper);
    });
  }

  var forkMap = this.forks;
  function runForks(i) {
    if (!forkMap[i]) return;
    var streams = forkMap[i].map(function(r) {
      console.log(r._toFork);
      return r(null, stream[r._toFork], {noWrite: true});
    });
    var s = proxy.mergeStreams(streams);
    // pipe(s);
    stream = s;
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
    if (_.isFunction(this.raw)) {
      // console.log("Run: " + this.raw.taskName);
      var s = this.raw.call(this, stream, this.opts);
      pipe(s);
    }
    wrapAfter(0);
  }

  runForks(0);
  // Run children
  this.children.forEach(function (runner, i) {
    if (i > 0) runForks(i + 1);
    wrapBefore(i + 1);
    stream = runner(null, stream, {noWrite: true});
    wrapAfter(i + 1);
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

  if (this.head === this && _.isFunction(cb)) {
    cb();
  } else {
    return stream;
  }

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
      'rename',
      'fork'
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
