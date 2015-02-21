exports.usage = "transaction_category_sort.coffee --source <file_path> --des <directory_path>"

exports.options =
  source:
    description: "The source file of the bank statement in tab separated values."
    required: yes
  dest:
    description: "The destination directory to output results. (default=cwd)"


CSV = require 'csv'

ACC = require './lib/'

TransactionRecord = require('./lib/transaction_record')


exports.main = (opts) ->
  read_csv(opts)
    .then(sort_by_category)
    .then(write_files(opts))
    .then(complete)
    .catch(LIB.fail);
  return


read_csv = (opts) ->
  stream = LIB.Path.create(opts.source).newReadStream()

  promise = new Promise (resolve, reject) ->

    to_array = (arry, count) ->
      resolve(arry.map(TransactionRecord.from_array))
      return

    CSV()
      .on('error', reject)
      .from.stream(stream)
      .to.array(to_array)
    return

  return promise


sort_by_category = (data) ->
  sorted = data.reduce( (sorted, record) ->
    if record.is_debit()
      unless category = sorted[record.category_key()]
        category = sorted[record.category] = []
      unless irs_category = sorted[record.irs_category_key()]
        irs_category = sorted[record.irs_category_key()] = []
      category.push(record)
      irs_category.push(record)
    else
      sorted.receipts.push(record)
    return sorted
  , {receipts: []})
  return sorted


write_files = (opts) ->
  dest_dir = LIB.Path.create(opts.dest)

  safe_filename = (key) ->
    return key.replace(/\s/g, '_').replace(/\&/g, 'and') + '.csv'

  write = (data) ->
    files = []
    promises = Object.keys(data).map (key) ->
      records = data[key]
      path = dest_dir.append(safe_filename(key))
      files.push(path)
      return ACC.middleware.write_csv(path)(records)

    return Promise.all(promises).then -> return {files: files}

  return write


complete = (state) ->
  state.files.forEach (file) -> print file.toString()
  return
