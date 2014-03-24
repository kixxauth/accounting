exports.usage = "bank_statement_to_transaction_log.coffee --config <file_path> --source <file_path> --dest <directory_path>"

exports.options =
  config:
    description: "The path to the configuration file (a CoffeeScript file)"
    required: yes
  source:
    description: "The source file of the bank statement in tab separated values."
    required: yes
  dest:
    description: "The destination directory to output results. (default=cwd)"

exports.help = """
Parse a bank statement data dump of tab separated values into a clean transaction log.
"""

ReadRawTransactionsPerformer  = require './lib/read_raw_transactions_performer'
ParseRawTransactionsPerformer = require './lib/parse_raw_transactions_performer'
MatchTransactionsPerformer    = require './lib/match_transactions_performer'
WriteTransactionLogsPerformer = require './lib/write_transaction_logs_performer'


exports.main = (opts) ->
  config = require(LIB.Path.create().resolve(opts.config).toString())
  dest_dir = LIB.Path.create(opts.dest)

  output =
    known_path: dest_dir.append('incomplete_transaction_log.csv')
    unknown_path: dest_dir.append('unknown_transactions.csv')

  ReadRawTransactionsPerformer.invoke({path: opts.source})
    .then(ParseRawTransactionsPerformer.create())
    .then(MatchTransactionsPerformer.create({matchers: config.matchers}))
    .then(WriteTransactionLogsPerformer.create({
      known_transactions_path: output.known_path
      unknown_transactions_path: output.unknown_path
    }))
    .then(complete)
    .catch(LIB.fail)
  return


complete = (state) ->
    print 'matched records:', state.known.length, 'unknown:', state.unknown.length
    print "You'll need to manually update the unknown records and cancat them with concat_transaction_log.coffee"
    print state.known_path.toString()
    print state.unknown_path.toString()
    return true

