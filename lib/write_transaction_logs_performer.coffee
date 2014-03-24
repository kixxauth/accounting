ACC       = require './'
Performer = require './performer'

class WriteTransactionLogsPerformer extends Performer

  initialize: (opts) ->
    @known_transactions_path = opts.known_transactions_path
    @unknown_transactions_path = opts.unknown_transactions_path

  perform: (data) ->
    write_known = ACC.middleware.write_csv(@known_transactions_path)(data.known)
    write_unknown = ACC.middleware.write_csv(@unknown_transactions_path)(data.unknown)

    promise = Promise.all([write_known, write_unknown]).then =>
      res =
        known: data.known
        known_path: @known_transactions_path
        unknown: data.unknown
        unknown_path: @unknown_transactions_path
      return res

    return promise

  @create = (opts) ->
    performer = new @({
      known_transactions_path: LIB.Path.create(opts.known_transactions_path)
      unknown_transactions_path: LIB.Path.create(opts.unknown_transactions_path)
    })
    return performer.perform

module.exports = WriteTransactionLogsPerformer
