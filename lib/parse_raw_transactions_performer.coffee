CSV = require 'csv'

Performer         = require './performer'
TransactionRecord = require './transaction_record'

class ParseRawTransactionsPerformer extends Performer

  perform: (text) ->
    promise = Promise.cast(text)
      .then(@split_lines)
      .then(@filter_lines)
      .then(@split_fields)
      .then(@create_records)
    return promise

  split_lines: (text) ->
    return text.split('\n')

  filter_lines: (lines) ->
    filtered_lines = lines.filter (line) ->
      start_date = /^[\d]{2}\/[\d]{2}\/[\d]{4}/.test(line)
      balance_line = /beginning balance/i.test(line)
      return start_date and not balance_line
    return filtered_lines

  split_fields: (lines) ->
    promise = new Promise (resolve, reject) ->

      to_array = (arry, count) ->
        return resolve(arry)

      CSV()
        .on('error', reject)
        .from.array(lines, {delimiter: '\t'})
        .to.array(to_array)
      return
    return promise

  create_records: (list) ->
    records = list.map (fields) ->
      rec = TransactionRecord.create({
        date:        fields[0]
        description: fields[1]
        amount:      fields[2]
      })
      return rec
    return records

  @create: ->
    performer = new @()
    return performer.perform

module.exports = ParseRawTransactionsPerformer
