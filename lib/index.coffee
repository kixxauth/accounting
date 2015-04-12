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
  if n then return NUM().unformat(n)
  return 0

exports.num_sort = (a, b) ->
  a = exports.ensure_number(a)
  b = exports.ensure_number(b)
  if a < b then return -1
  if a > b then return 1
  return 0

sum = (a, b) ->
  return a + b

subtract = (a, b) ->
  return a - b

round = (n) ->
  return NUM(n.toFixed(2)).valueOf()


exports.writeCSV = (path, data) ->
  return new Promise (resolve, reject) ->
    CSV.stringify data, (err, text) ->
      if err then return reject(err)
      path.write(text).then(resolve, reject)
      return
