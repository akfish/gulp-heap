var _ = require('underscore'),
  gulp = require('gulp'),
  gutil = require('gulp-util'),
  rename = require('gulp-rename');

function runner(src, dst, action) {
  var context = {
    hasContext: true,
    src: src,
    dst: dst,
    _last: null,
    toggled: true,
    then: function(task) {
      this.actions.push(task);
      this._last = task;
      return this;
    },
    with: function(wrapper) {
      if (!wrapper.isWrapper) throw new TypeError(wrapper + " is not a wrapper");
      if (this.actions.length === 0) throw new ReferenceError("No actions to be wrapped");
      this.wrappers.push({wrapper: wrapper, targetAction: this.actions.length - 1});
      this._last = wrapper;
      return this;
    },
    wrappers: [],
    actions: [],
    if: function(toggle) {
      if (!this._last) throw new ReferenceError("No actions to be toggled");
      this._last.toggled = toggle;
      return this;
    },
    ifNot: function(toggle) {
      if (!this._last) throw new ReferenceError("No actions to be toggled");
      this._last.toggled = !toggle;
      return this;
    },
    dest: function(dst) {
      // TODO:
      return this;
    },
    rename: function(opts) {
      r = makeTask(function(stream, o) {
        return rename(o);
      })(opts);
      return this.then(r);
    }
  };

  if (action) {
    context.actions.push(action);
    context._last = action;
    action.toggled = true;
  }

  var fn = function(cb, stream, noWrite) {
    if (!stream) {
      stream = gulp.src(context.src).on('error', gutil.log);//[context.src];
    }
    var tryGetWrapper = function(i) {
      if (context.wrappers.length === 0) return;
      if (context.wrappers[0].targetAction === i) {
        return context.wrappers.shift().wrapper;
      }
    };

    context.actions.forEach(function (action, i) {
      var wrapper = tryGetWrapper(i);
      if (wrapper && wrapper.toggled) stream.pipe(wrapper.begin.call(this, stream, wrapper.beginOpts));
      if (action.toggled) {
        if (action.hasContext) {
          action(cb, stream, true);
        } else {
          stream.pipe(action.call(this, stream, action.opts));
        }
      } else {
        console.log(action);
      }
      if (wrapper && wrapper.toggled) stream.pipe(wrapper.end.call(this, stream, wrapper.endOpts));
    }, this);
    if (!noWrite) stream.pipe(gulp.dest(context.dst));
    // stream.push(context.dst);
    return stream;
  };
  _.extend(fn, context);
  return fn;
}

function task(args, raw, defaultOpts) {
  if (args.length <= 1) {
    var opts;
    if (args.length === 1) opts = args[0];
    raw.opts = _.isFunction(opts) ? opts : _.defaults({}, defaultOpts, opts);
    raw.toggled = true;
    return raw;
  }
  raw.opts = _.defaults({}, defaultOpts, args[2]);
  raw.toggled = true;
  return runner(args[0], args[1], raw);
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
  return function(opts) {
    var oBegin = _.isFunction(defaultBeginOpts) ? defaultBeginOpts : _.defaults({}, defaultBeginOpts, opts),
      oEnd = _.isFunction(defaultEndOpts) ? defaultEndOpts : _.defaults({}, defaultEndOpts, opts);
    return wrapper(beginWrapper, EndWrapper, oBegin, oEnd);
  };
}

module.exports.task = makeTask;

module.exports.wrapper = makeWrapper;
