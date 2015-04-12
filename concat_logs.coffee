exports.usage = "--a <file_path> --b <file_path> --dest <directory_path>"

exports.options =
  a:
    describe: "The path to the A source"
    required: yes
  b:
    describe: "The path to the B source"
    required: yes
  dest:
    describe: "The destination directory to output results."

exports.help = """
Merges to transaction log files together and orders the records by date.
"""

exports.main = (API) ->
  argv    = API.argv()

  args =
    pathA      : API.path().resolve(argv.a)
    pathB      : API.path().resolve(argv.b)
    outputPath : API.path().resolve(argv.dest).append('sorted_transactions.csv')

  performAction = createPerformAction(API)

  onsuccess = (args) ->
    print 'total records', args.records.length
    print args.outputPath.toString()
    return true

  onerror = (err) ->
    console.error "Runtime Error:"
    console.error err.stack or err.message or err
    return process.exit(1)

  return performAction.run(API, args).then(onsuccess, onerror)


createPerformAction = (API) ->

  LIB               = require './lib/'
  TransactionRecord = require './lib/transaction_record'

  factory = API.factory [API.mixins('Action')],

    # args.pathA
    # args.pathB
    # args.outputPath
    initialize: ->
      @q 'readSources'
      @q 'sortRecords'
      @q 'writeRecords'

    readSources: (API, args) ->
      promises = [
        LIB.readCSV(args.pathA)
        LIB.readCSV(args.pathB)
      ]
      return Promise.all(promises).then (lists) ->
        args.records = Array::concat.apply([], lists)
          .map(TransactionRecord.from_array)
        return args

    sortRecords: (API, args) ->
      args.records.sort(TransactionRecord.sort_by_date)
      return args

    writeRecords: (API, args) ->
      records = args.records.map (transaction) ->
        return transaction.to_array()
      return LIB.writeCSV(args.outputPath, records)


  return factory()
