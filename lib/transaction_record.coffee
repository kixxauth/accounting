MOMENT = require 'moment'
NUMERAL = require 'numeral'


class TransactionRecord

  constructor: (spec) ->
    @date         = spec.date
    @type         = spec.type
    @amount       = spec.amount
    @vendor       = spec.vendor
    @description  = spec.description
    @category     = spec.category
    @irs_category = spec.irs_category

  update: (attrs) ->
    return TransactionRecord.create(LIB.extend(@, attrs))

  to_array: ->
    arry = [
      @format_date()
      @get_type()
      @format_amount()
      @vendor
      @description
      @category
      @irs_category
    ]
    return arry

  format_amount: ->
    unless LIB.isNumber(@amount) then return @amount
    return NUMERAL(@amount).format('(0,0.00)')

  format_date: ->
    unless @date then return 'YYYY-MM-DD'
    return MOMENT(@date).format('YYYY-MM-DD')

  get_type: ->
    return if TransactionRecord.parse_raw_amount(@amount) < 0 then 'debit' else 'credit'

  @parse_raw_date: (str) ->
    if LIB.isObject(str) then return str
    return MOMENT(str, "MM/DD/YYYY").toDate()

  @parse_raw_amount: (str) ->
    if LIB.isNumber(str) then return str
    return NUMERAL().unformat(str)

  @sort_by_date = (a, b) ->
    a = MOMENT(a.format_date()).toDate().getTime()
    b = MOMENT(b.format_date()).toDate().getTime()
    return -1 if a < b
    return 1 if a > b
    return 0

  @from_array = (data) ->
    record = new TransactionRecord({
      date: data[0]
      type: data[1]
      amount: data[2]
      vendor: data[3]
      description: data[4]
      category: data[5]
      irs_category: data[6]
    })
    return record

  @from_raw_array = (data) ->
    record = new TransactionRecord({
      date: @parse_raw_date(data[0])
      description: data[1]
      amount: @parse_raw_amount(data[2])
    })
    return record

  @create = (data) ->
    return new TransactionRecord(data)

exports.TransactionRecord = TransactionRecord