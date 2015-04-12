require('enginemill').module (API) ->

  CSV               = require 'csv'
  TransactionRecord = require '../transaction_record'


  Parser =

    initialize: ->
      this.q 'filterLines'
      this.q 'splitFields'
      this.q 'createRecords'

    returns: 'records'

    splitLines: (API, args) ->
      return args

    filterLines: (API, args) ->
      args.data = args.rawData.split('\n').map( (line) ->
        return line.trim()
      ).filter( (line) ->
        hasDate = /^[\d]{2}\/[\d]{2}\/[\d]{4}/.test(line)
        isBalanceLine = /beginning balance/i.test(line)
        return hasDate and not isBalanceLine
      ).join('\n')
      return args

    splitFields: (API, args) ->
      opts =
        delimiter    : '\t'
        rowDelimiter : '\n'

      return new Promise (resolve, reject) ->
        CSV.parse args.data, opts, (err, data) ->
          if err then return reject(err)
          args.data = data
          return resolve(args)

    createRecords: (API, args) ->
      args.records = args.data.map (fields) ->
        return TransactionRecord.create
          date:        fields[0]
          description: fields[1]
          amount:      fields[2]
      return args


  # Create singleton
  module.exports = API.factory([API.mixins('Action')], Parser)()
