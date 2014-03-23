class FormDataPerformer
  perform: ->
    return null

  @create = (opts) ->
    print 'CONSTRUCTOR', @
    performer = new @()
    return performer.perform

  @invoke = (opts, input) ->
    return @create(opts)(input)

module.exports = FormDataPerformer
