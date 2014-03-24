class Matcher

  constructor: (spec) ->
    @regex        = spec.regex
    @vendor       = spec.vendor
    @description  = spec.description
    @category     = spec.category
    @irs_category = spec.irs_category

  match: (record) ->
    unless @regex.test(record.description) then return
    rv = record.update({
      vendor: @vendor
      description: @description
      category: @category
      irs_category: @irs_category
    })
    return rv

  attributes: ->
    attrs =
      vendor: @vendor
      description: @description
      category: @category
      irs_category: @irs_category
    return attrs

  @create = (spec) ->
    return new Matcher(spec)


module.exports = Matcher
