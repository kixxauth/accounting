Performer = require './performer'

class ReadRawTransactionsPerformer extends Performer

  initialize: (opts) ->
    @path = opts.path
    return @

  perform: ->
    return @path.read()

  @create = (opts) ->
    path = LIB.Path.create(opts.path)
    performer = new @({path: path})
    return performer.perform

  @invoke = (opts, data) ->
    return @create(opts)(data)

module.exports = ReadRawTransactionsPerformer
