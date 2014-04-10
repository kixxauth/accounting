NUM = require 'numeral'
CSV = require 'csv'

TransactionRecord = require './transaction_record'


exports.sum = (numbers) ->
  unless LIB.isArray(numbers)
    numbers = LIB.toArray(arguments)
  return numbers.map(exports.ensure_number).reduce(sum, 0)

exports.subtract = ->
  numbers = LIB.toArray(arguments).map(exports.ensure_number)
  first = numbers.shift()
  return numbers.reduce(subtract, first)

exports.multiply = (a, b) ->
  return round(NUM(a).multiply(b).valueOf())

exports.ensure_number = (n) ->
  return NUM().unformat(n)

sum = (a, b) ->
  return a + b

subtract = (a, b) ->
  return a - b

round = (n) ->
  return NUM(n.toFixed(2)).valueOf()


exports.middleware =

  write_csv: (path, options) ->
    write = (data) ->
      promise = new Promise (resolve, reject) ->
        on_end = (count) -> resolve(path)

        on_error = (err) -> reject(err)

        record_to_a = (rec) ->
          return rec if Array.isArray(rec)
          return rec.to_array()

        print options
        CSV().from.array(data.map(record_to_a))
          .to.stream(path.newWriteStream(), options)
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
