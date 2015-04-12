MOMENT  = require 'moment'
NUMERAL = require 'numeral'


class TransactionRecord
  @FRESHBOOKS_EXPENSE_COLUMNS = [
    'date'
    'vendor'
    'category'
    'notes'
    'amount'
  ]

  constructor: (spec) ->
    @date         = spec.date
    @type         = spec.type
    @amount       = spec.amount
    @vendor       = spec.vendor
    @description  = spec.description
    @category     = spec.category
    @irs_category = spec.irs_category

  update: (attrs) ->
    return TransactionRecord.create(U.extend(@, attrs))

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

  to_freshbooks_expense: ->
    arry = [
      @format_slash_date()
      @vendor
      @category
      @description
      @format_amount_neg()
    ]
    return arry

  format_amount: ->
    unless U.isNumber(@amount) then return @amount
    return NUMERAL(@amount).format('(0,0.00)')

  format_date: ->
    unless @date then return 'YYYY-MM-DD'
    return MOMENT(@date).format('YYYY-MM-DD')

  format_slash_date: ->
    unless @date then return 'MM/DD/YY'
    return MOMENT(@date).format('MM/DD/YY')

  format_amount_neg: ->
    unless U.isNumber(@amount) then return @amount
    return NUMERAL(@amount).format('-0,0.00')

  get_type: ->
    return if TransactionRecord.parse_amount(@amount) < 0 then 'debit' else 'credit'

  is_debit: ->
    return @type is 'debit'

  category_key: ->
    unless @category then return 'NA'
    return @category

  irs_category_key: ->
    unless @irs_category then return 'irs -- NA'
    return "irs -- #{@irs_category}"

  @parse_date = (date) ->
    if date instanceof Date then return date
    if /[\d]{4}-[\d]{2}-[\d]{2}/.test(date)
      return MOMENT(date, "YYYY-MM-DD").toDate()
    return MOMENT(date, "MM/DD/YYYY").toDate()

  @parse_amount = (amount) ->
    if U.isNumber(amount) then return amount
    return NUMERAL().unformat(amount)

  @sort_by_date = (a, b) ->
    a = MOMENT(a.format_date()).toDate().getTime()
    b = MOMENT(b.format_date()).toDate().getTime()
    return -1 if a < b
    return 1 if a > b
    return 0

  @from_array = (data) ->
    record = new TransactionRecord
      date         : TransactionRecord.parse_date(data[0])
      type         : data[1]
      amount       : TransactionRecord.parse_amount(data[2])
      vendor       : data[3]
      description  : data[4]
      category     : data[5]
      irs_category : data[6]
    return record

  @create = (spec) ->
    rec = new TransactionRecord
      date         : TransactionRecord.parse_date(spec.date)
      type         : spec.type
      amount       : TransactionRecord.parse_amount(spec.amount)
      vendor       : spec.vendor
      description  : spec.description
      category     : spec.category
      irs_category : spec.irs_category
    return rec

module.exports = TransactionRecord
