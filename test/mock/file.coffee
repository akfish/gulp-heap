_ = require('underscore')
COUNTER = 0

module.exports =
class File
  constructor: (@src, @srcOpts) ->
    @id = COUNTER++
    @name = @src
    @content = []

  clone: ->
    # Possible bug: @srcOpts not deep cloned if it contains nested obj
    # or array
    cloned = new File(@src, _.clone(@srcOpts))
    cloned.name = @name

    cloned.content = @content.map (item) -> _.clone(item)

    cloned
