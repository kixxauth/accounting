ACC = require './'

sum           = ACC.sum
subtract      = ACC.subtract
multiply      = ACC.multiply
ensure_number = ACC.ensure_number
num_sort      = ACC.num_sort


class Form_2441
  constructor: (@form) ->

  compute: ->
    @form.max_amount = @max_amount()
    @form.multiplier = @multiplier()
    @form.tentative_credit = @tentative_credit()
    @form.credit = @form.tentative_credit
    return @form

  max_amount: ->
    list = [
      ensure_number(@form.my_earned_income)
      ensure_number(@form.spouse_earned_income)
      ensure_number(@form.line_3)
    ]
    return list.sort(num_sort).shift()

  multiplier: ->
    if @form.adjusted_gross_income <= 43000
      throw new Error('Cannot compute dependent care tax credit multiplier.')
    return 0.2

  tentative_credit: ->
    return multiply(@form.max_amount, @form.multiplier)

  # form.amount_paid - Number
  # form.line_3 - Number
  # form.my_earned_income - Number
  # form.spouse_earned_income - Number
  # form.adjusted_gross_income - Number
  @create = (form) ->
    return new Form_2441(form)

exports.Form_2441 = Form_2441

