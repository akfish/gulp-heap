var _ = require('underscore'),
  gulp = require('gulp'),
  gutil = require('gulp-util'),
  rename = require('gulp-rename'),
  plumber = require('gulp-plumber');

var RUNNER_COUNTER = 0;
function runner(src, dst, action) {
  var context = {
    id: RUNNER_COUNTER,
    hasContext: true,
    src: src,
    dst: dst,
    _handled: false,
    _nexts: [],
    _selection: null,
    toggled: true,
    srcOpts: {},
    dstOpts: {},
    // wrappers: [],
    _wrapperMap: {
      begin: {},
      end: {}
    },
    actions: [],
    _getTarget: function() {
      if (this._nexts.length === 0) return this;
      return this._nexts[this._nexts.length - 1];
    },
    _getSelection: function() {
      if (!this._selection) {
        return {
          from: this.actions.length - 1,
          to: this.actions.length - 1
        };
      }
      return this._selection;
    },
    _clearSelection: function() {
      this._selection = null;
    },
    source: function(src, opts) {
      if (_.isString(src)) {
        if (_.isString(context.src)) {
          console.warn("Source '" + context.src + "' has already been set. Overrided with '" + src + "'.");
        }
        context.src = src;
      } else {
        opts = src;
      }
      context.srcOpts = _.defaults({}, opts);
      return this;
    },
    dest: function(dst, opts) {
      if (_.isString(dst)) {
        if (_.isString(context.dst)) {
          console.warn("Destination '" + context.src + "' has already been set. Overrided with '" + dst + "'");
        }
        context.dst = dst;
      } else {
        opts = dst;
      }
      context.dstOpts = _.defaults({}, opts);
      return this;
    },
    then: function(task) {
      var target = this._getTarget();
      target.actions.push(task);
      target._last = task;
      return this;
    },
    wrap: function(count) {
      var from = this.actions.length - count;
      if (from < 0 || from >= this.actions.length) throw new RangeError("Wrap count out of range");
      this._selection = {
        from: from,
        to: this.actions.length - 1
      };
      return this;
    },
    wrapAll: function() {
      this._selection = {
        from: 0,
        to: this.actions.length - 1
      };
      return this;
    },
    with: function(wrapper) {
      var target = this._getTarget();
      if (!wrapper.isWrapper) throw new TypeError(wrapper + " is not a wrapper");
      if (target.actions.length === 0) throw new ReferenceError("No actions to be wrapped");
      var sel = target._getSelection();
      // target.wrappers.push({wrapper: wrapper, targetAction: target.actions.length - 1, sel: sel});
      target._last = wrapper;
      var map = target._wrapperMap;
      if (!map.begin[sel.from]) map.begin[sel.from] = [];
      map.begin[sel.from].unshift(wrapper); // LIFO
      if (!map.end[sel.to]) map.end[sel.to] = [];
      map.end[sel.to].push(wrapper);
      target._clearSelection();
      return this;
    },
    if: function(toggle) {
      var target = this._getTarget();
      if (!target._last) throw new ReferenceError("No actions to be toggled");
      target._last.toggled = toggle;
      return this;
    },
    ifNot: function(toggle) {
      var target = this._getTarget();
      if (!target._last) throw new ReferenceError("No actions to be toggled");
      target._last.toggled = !toggle;
      return this;
    },
    write: function(dst, opts) {
      var target = this._getTarget();
      var d = makeTask(function(stream, o) {
        return gulp.dest(o, opts);
      })(dst);
      target.then(d);
      return this;
    },
    rename: function(opts) {
      var target = this._getTarget();
      var r = makeTask(function(stream, o) {
        return rename(o);
      })(opts);
      target.then(r);
      return this;
    },
    next: function(task) {
      this._nexts.push(task);
      return this;
    },
  };

  if (action) {
    context.actions.push(action);
    context._last = action;
    action.toggled = true;
  }

  var fn = function(cb, stream, noWrite) {
    // console.log("Context: #" + context.id);
    if (!stream && context.src) {
      console.log("Src: " + context.src + ", " + JSON.stringify(context.srcOpts));
      stream = gulp.src(context.src, context.srcOpts).on('error', gutil.log).pipe(plumber());//[context.src];
    }
    // var tryGetWrapper = function(i) {
    //   if (context.wrappers.length === 0) return;
    //   if (context.wrappers[0].targetAction === i) {
    //     return context.wrappers.shift().wrapper;
    //   }
    // };

    function runWrapper(m, i, cb) {
      if (!m[i]) return;
      m[i].forEach(function (wrapper) {
        if (!wrapper.toggled) return;
        cb(wrapper);
      });
    }

    context.actions.forEach(function (action, i) {
      // var wrapper = tryGetWrapper(i);
      // if (wrapper && wrapper.toggled) {
      //   stream = stream.pipe(wrapper.begin.call(this, stream, wrapper.beginOpts));
      // }
      runWrapper(context._wrapperMap.begin, i, function(wrapper) {
        stream = stream.pipe(wrapper.begin.call(context, stream, wrapper.beginOpts));
      });
      if (action.toggled) {
        if (action.hasContext) {
          stream = action(cb, stream, true);
        } else {
          var s = action.call(this, stream, action.opts);
          if (stream) {
            stream = stream.pipe(s);
          } else {
            stream = s;
          }
        }
      }
      runWrapper(context._wrapperMap.end, i, function(wrapper) {
        stream = stream.pipe(wrapper.end.call(context, stream, wrapper.endOpts));
      });
      // if (wrapper && wrapper.toggled) {
      //   stream = stream.pipe(wrapper.end.call(this, stream, wrapper.endOpts));
      // }
    }, this);
    if (!noWrite && _.isString(context.dst)) {
      console.log("Dst: " + context.dst + ", " + JSON.stringify(context.dstOpts));
      stream = stream.pipe(gulp.dest(context.dst, context.dstOpts));
    }

    context._handled = true;

    context._nexts.forEach(function (next) {
      next(cb, stream);
    });
    // stream.push(context.dst);
    return stream;
  };
  _.extend(fn, context);
  RUNNER_COUNTER++;
  return fn;
}

function defaults(defaultOpts, opts) {
  if (_.isString(opts) || _.isFunction(opts)) return opts;
  return _.defaults({}, opts, defaultOpts);
}

function task(args, raw, defaultOpts) {
  var src, dst, opts;
  switch (args.length) {
    case 1:
      opts = args[0];
      break;
    case 2:
      src = args[0];
      dst = args[1];
      break;
    case 3:
      src = args[0];
      dst = args[1];
      opts = args[2];
      break;
    default:
  }
  raw.opts = defaults(defaultOpts, opts);
  raw.toggled = true;
  return runner(src, dst, raw);
}

function wrapper(beginWrapper, EndWrapper, beginOpts, endOpts) {
  return {
    isWrapper: true,
    toggled: true,
    beginOpts: beginOpts,
    endOpts: endOpts,
    begin: beginWrapper,
    end: EndWrapper
  };
}

function makeTask(raw, defaultOpts) {
  return function(src, dst, opts) {
    return task(arguments, raw, defaultOpts);
  };
}

function makeWrapper(beginWrapper, EndWrapper, defaultBeginOpts, defaultEndOpts) {
  return function(beginOpts, endOpts) {
    var oBegin = defaults(defaultBeginOpts, beginOpts),
      oEnd = defaults(defaultEndOpts, endOpts);
    return wrapper(beginWrapper, EndWrapper, oBegin, oEnd);
  };
}

module.exports.task = makeTask;

module.exports.wrapper = makeWrapper;
