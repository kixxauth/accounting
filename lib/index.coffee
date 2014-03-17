CSV = require 'csv'

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
