CSV = require 'csv'

TransactionRecord = require './transaction_record'


exports.middleware =

  write_csv: (path) ->
    write = (data) ->
      promise = new Promise (resolve, reject) ->
        on_end = (count) -> resolve(path)
        on_error = (err) -> reject(err)
        record_to_a = (rec) -> return rec.to_array()

        CSV().from.array(data.map(record_to_a))
          .to.stream(path.newWriteStream())
          .on('end', on_end)
          .on('error', on_error)
        return
      return promise

    return write

  read_csv: (path) ->
    stream = path.newReadStream()

    read = ->
      promise = new Promise (resolve, reject) ->
        on_end = (data, count) -> resolve(data.map(TransactionRecord.from_array))
        on_error = (err) -> reject(err)
        CSV().from.stream(stream).to.array(on_end).on('error', on_error)
        return
      return promise

    return read
