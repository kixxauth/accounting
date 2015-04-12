require('enginemill').module (API) ->

  TransactionMatcher = require '../transaction_matcher'

  Matcher =

    initialize: (spec) ->
      @matchers = spec.matchers.map(TransactionMatcher.create)

    run: (records) ->
      sort = @sort.bind(@)
      return records.reduce(sort, {known: [], unknown: []})

    sort: (sorted, record) ->
      if match = @findMatch(record)
        sorted.known.push(record.update(match.attributes()))
      else
        sorted.unknown.push(record)
      return sorted

    findMatch: (record) ->
      match = U.find @matchers, (matcher) -> return matcher.match(record)
      return match if match

  module.exports = API.factory(Matcher)
