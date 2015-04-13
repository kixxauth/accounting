exports.usage = "--source <file_path> --dest <directory_path>"

exports.options =
  source:
    describe: "The source file of the transaction log in comma separated values."
    required: yes
  dest:
    describe: "The destination directory to output results."
    required: yes

exports.help = """
Prepare a bank transaction log for import as Freshbooks expenses. Filters out
cash withdrawls and credits.
"""

exports.main = (API) ->
  argv = API.argv()

  args =
    sourcePath: API.path().resolve(argv.source)
    outputPath: API.path().resolve(argv.dest).append('freshbooks_expenses.csv')

  performAction = createPerformAction(API)

  onsuccess = (args) ->
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

    # args.sourcePath
    # args.outputPath
    initialize: ->
      @q 'readSource'
      @q 'filter'
      @q 'writeRecords'

    readSource: (API, args) ->
      return LIB.readCSV(args.sourcePath).then (data) ->
        args.records = data.map(TransactionRecord.from_array)
        return args

    filter: (API, args) ->
      args.records = U.filter(args.records, (record) ->
        return no if record.type is 'credit'
        unless record.category
          throw new Error("Uncategorized record: #{record.date}, #{record.description}")
        return yes
      ).map( (record) ->
        return record.to_freshbooks_expense()
      )
      return args

    writeRecords: (API, args) ->
      args.records.unshift(TransactionRecord.FRESHBOOKS_EXPENSE_COLUMNS)
      return LIB.writeCSV(args.outputPath, args.records)

  return factory()
