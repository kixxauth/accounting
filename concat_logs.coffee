exports.usage = "concat_logs.coffee --a <file_path> --b <file_path> --dest <directory_path>"

exports.options =
  a:
    description: "The path to the A source"
    required: yes
  b:
    description: "The path to the B source"
    required: yes
  dest:
    description: "The destination directory to output results. (default=cwd)"

exports.help = """
Merges to transaction log files together and orders the records by date.
"""

ACC = require './lib/'

TransactionRecord = require './lib/transaction_record'


exports.main = (opts) ->
  read_sources(opts)()
    .then(sort_records)
    .then(write_records({dest_dir: opts.dest}))
    .then(complete)
    .catch(LIB.fail);
  return


read_sources = (opts) ->
  a_path = LIB.Path.create(opts.a)
  b_path = LIB.Path.create(opts.b)

  read = ->
    promise_a = ACC.middleware.read_csv(a_path)()
    promise_b = ACC.middleware.read_csv(b_path)()

    to_array = (lists) -> return lists[0].concat(lists[1])

    return Promise.all([promise_a, promise_b]).then(to_array)
  return read


sort_records = (records) ->
  records.sort(TransactionRecord.sort_by_date)
  return records


write_records = (opts) ->
  path = LIB.Path.create(opts.dest_dir).append('transaction_log.csv')
  write_csv = ACC.middleware.write_csv(path)

  write = (data) ->
    return write_csv(data).then -> return {path: path, length: data.length}
  return write


complete = (state) ->
  print 'total records', state.length
  print state.path.toString()

