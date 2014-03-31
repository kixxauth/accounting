exports.usage = "freshbooks_expenses.coffee --source <file_path> --des <directory_path>"

exports.options =
  source:
    description: "The source file of the transaction log in comma separated values."
    required: yes
  dest:
    description: "The destination directory to output results. (default=cwd)"

exports.help = """
Prepare a bank transaction log for import as Freshbooks expenses. Filters out
cash withdrawls and credits.
"""

TransactionRecord = require './lib/transaction_record'

ACC = require './lib/'


exports.main = (opts) ->
  source_path = LIB.Path.create(opts.source)
  dest_path = LIB.Path.create(opts.dest).append('freshbooks_expenses.csv')

  translate = ->
    return dest_path

  ACC.middleware.read_csv(source_path)()
    .then(filter)
    .then(to_freshbooks)
    .then(write_csv(dest_path))
    .then(translate)
    .then(complete)
    .catch(LIB.fail);
  return


filter = (transactions) ->
  keepers = LIB.filter transactions, (record) ->
    return no if record.type is 'credit'
    unless record.category
      throw new Error("Uncategorized record: #{record.date},#{record.description}")
    return no if record.category is 'cash'
    return yes
  return keepers


to_freshbooks = (expenses) ->
  records = expenses.map (record) ->
    return record.to_freshbooks_expense()
  return records


write_csv = (path) ->
  opts =
    columns: TransactionRecord.FRESHBOOKS_EXPENSE_COLUMNS
    header: yes

  writer = (expenses) ->
    return ACC.middleware.write_csv(path, opts)(expenses)
  return writer


complete = (path) ->
  print path.toString()
  return
