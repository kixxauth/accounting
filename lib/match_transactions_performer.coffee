Performer          = require './performer'
TransactionMatcher = require './transaction_matcher'

class MatchTransactionsPerformer extends Performer

  initialize: (opts) ->
    @matchers = opts.matchers

  perform: (records) ->
    sort = @sort.bind(@)
    data = records.reduce(sort, {known: [], unknown: []})
    return data

  sort: (sorted, record) ->
    if match = @find_match(record)
      sorted.known.push(record.update(match.attributes()))
    else
      sorted.unknown.push(record)
    return sorted

  find_match: (record) ->
    match = LIB.find @matchers, (matcher) ->
      return matcher.match(record)
    return match if match

  @create = (opts) ->
    matchers = opts.matchers.map(TransactionMatcher.create)
    performer = new @({matchers: matchers})
    return performer.perform


module.exports = MatchTransactionsPerformer
