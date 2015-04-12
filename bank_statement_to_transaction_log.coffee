exports.usage = "--config <file_path> --source <file_path> --dest <directory_path>"

exports.options =
  config:
    describe: "The path to the configuration file (a CoffeeScript file)"
    required: yes
  source:
    describe: "The source file of the bank statement in tab separated values."
    required: yes
  dest:
    describe: "The destination directory to output results."
    required: yes

exports.help = """
Parse a bank statement data dump of tab separated values into a clean transaction log.
"""


exports.main = (API) ->
  argv    = API.argv()
  destDir = API.path().resolve(argv.dest)

  args =
    configPath  : API.path().resolve(argv.config)
    sourcePath  : API.path().resolve(argv.source)
    knownPath   : destDir.append('incomplete_transaction_log.csv')
    unknownPath : destDir.append('unknown_transactions.csv')

  performAction = createPerformAction(API)

  onsuccess = (args) ->
    print 'matched records:', args.records.known.length, 'unknown:', args.records.unknown.length
    print """
    You'll need to manually update the unknown records and cancat them
    with concat_transaction_log.coffee
    """
    print args.knownPath.toString()
    print args.unknownPath.toString()
    return true

  onerror = (err) ->
    console.error "Runtime Error:"
    console.error err.stack or err.message or err
    return process.exit(1)

  return performAction.run(API, args).then(onsuccess, onerror)


createPerformAction = (API) ->
  LIB                  = require('./lib/')
  parseRawTransactions = require('./lib/actions/parse_raw_transactions')
  transactionMatcher   = require('./lib/actions/match_transactions')

  factory = API.factory [API.mixins('Action')],

    # args.configPath
    # args.sourcePath
    # args.knownPath
    # args.unknownPath
    initialize: ->
      this.q 'readRawTransactions'
      this.q 'parseRawTransactions'
      this.q 'getConfigs'
      this.q 'matchTransactions'
      this.q 'writeFiles'

    readRawTransactions: (API, args) ->
      args.sourcePath.read().then (data) ->
        if not data
          throw new Error "Source data not found at #{args.sourcePath}"
        args.rawData = data
        return args

    parseRawTransactions: (API, args) ->
      parseRawTransactions
        .run(API, { rawData: args.rawData })
        .then (records) ->
          args.records = records
          return args

    getConfigs: (API, args) ->
      args.configs = require args.configPath.toString()

    matchTransactions: (API, args) ->
      args.records = transactionMatcher({ matchers: args.configs.matchers })
        .run(args.records)

      mapper = (transaction) -> return transaction.to_array()

      args.records.known = args.records.known.map(mapper)
      args.records.unknown = args.records.unknown.map(mapper)
      return args

    writeFiles: (API, args) ->
      return Promise.all([
        LIB.writeCSV(args.knownPath, args.records.known)
        LIB.writeCSV(args.unknownPath, args.records.unknown)
      ])

  return factory()
