exports.usage = "personal_taxes.coffee --form <file_path>"

exports.options =
  form:
    description: "The path to the input form."
    required: yes

exports.help = """
Compute tax forms and output results.
"""

ACC = require './lib'
Schedule_C = require('./lib/schedule_c').Schedule_C
Form_2441 = require('./lib/form_2441').Form_2441

sum      = ACC.sum
subtract = ACC.subtract
multiply = ACC.multiply


exports.main = (opts) ->
  state =
    form_path: opts.form
    other_taxes: Object.create(null)

  Promise.cast(LIB.Crystal.create(state))
    .then(read_form)
    .then(compute_schedule_c)
    .then(compute_income)
    .then(compute_self_employment_tax)
    .then(compute_adjusted_gross_income)
    .then(compute_base_tax)
    .then(compute_credits)
    .then(compute_total_tax)
    .then(compute_payments)
    .then(compute_tax)
    .catch(LIB.fail)
  return


compute_schedule_c = (state) ->

  log = (prop, val) ->
    log_value("Schedule C -- #{prop}", val)
    return

  log_expense = (prop, val) ->
    return log("expenses -- #{prop}", val)

  form = Schedule_C.create(state.schedule_c).compute()

  log('line 1', form.gross_receipts)
  log('line 3', form.net_receipts)
  log('line 4', form.cost_of_goods_sold)
  log('line 5 Gross Profit', form.gross_profit)
  log('line 7 Gross Income', form.gross_income)

  for own expense, amount of form.expenses
    log_expense(expense, amount)

  log('line 28 Total expenses', form.total_expenses)
  log('line 29 Tentative profit', form.total_expenses)
  log('line 30a', form.home_business_use.total_square_footage)
  log('line 30b', form.home_business_use.used_square_footage)
  log('line 30 Business use of home', form.business_use_of_home)
  log('line 31 Net profit', form.net_profit)
  return state


compute_income = (state) ->
  form = state['1040'].income

  form.business_income = state.schedule_c.net_profit

  income = []
  for own name, amount of form
    income.push(amount)

  state.define('total_income', sum(income))

  log_value('line 7 wages', form.wages)
  log_value('line 8a taxable interest', form.taxable_interest)
  log_value('line 9a ordinary dividends', form.ordinary_dividends)
  log_value('line 12 business income', form.business_income)
  log_value('line 13 capital gain', form.capital_gain)
  log_value('line 17 s-corp income', form.s_corp_income)
  log_value('line 22 total income', state.total_income)
  return state


compute_self_employment_tax = (state) ->
  tax = 0

  profit = state.schedule_c.net_profit
  log_value('Schedule SE -- line 3', profit)

  check = multiply(profit, 0.9235)
  log_value('Schedule SE -- line 4', check)

  if check < 400
    print "We don't have to pay self employment tax!"
  else if check <= 113700
    tax = multiply(check, 0.153)
  else
    tax = multiply(check, 0.029)
    tax = sum(tax, '14,098.80')

  state.other_taxes.self_employment_tax = tax
  log_value('Schedule SE -- line 5', tax)
  state.define('deductable_self_employment_tax', multiply(tax, 0.5))
  log_value('Schedule SE -- line 6', state.deductable_self_employment_tax)
  return state


compute_adjusted_gross_income = (state) ->
  form = state['1040'].deductions
  form.deductable_self_employment_tax = state.deductable_self_employment_tax

  deductions = []
  for own name, amount of form
    deductions.push(amount)

  state.define('deductions', sum(deductions))
  agi = subtract(state.total_income, state.deductions)
  state.define('adjusted_gross_income', agi)

  log_value('line 26', form.moving_expenses)
  log_value('line 27', form.deductable_self_employment_tax)
  log_value('line 32', form.ira_deduction)
  log_value('line 36', state.deductions)
  log_value('line 37 Adusted Gross Income', agi)
  return state


compute_base_tax = (state) ->
  form = state['1040']

  if state.adjusted_gross_income > 150000
    throw new Error("Can't compute exemptions above $150k adjusted gross income")

  after_deduction = subtract(state.adjusted_gross_income, form.standard_deduction)

  state.define('exemption_amount', multiply(form.exemptions, 3900))

  state.define('taxable_income', subtract(after_deduction, state.exemption_amount))

  # Base tax needs to be looked up in the tax table and manually entered in the form.
  state.define('base_tax', state['1040'].base_tax)

  log_value('line 40', form.standard_deduction)
  log_value('line 41', after_deduction)
  log_value('line 42 exemptions', state.exemption_amount)
  log_value('line 43 taxable income', state.taxable_income)
  print "Enter base_tax based on this value ->", state.taxable_income
  log_value('line 44 Tax', state.base_tax)

  state.define('total_base_tax', sum(state.base_tax, alternative_minimum_tax = 0))
  return state


compute_credits = (state) ->
  compute_dependent_care_credit(state)
  state.define('dependent_care_credit', state['2441'].credit)
  credits = sum([
    state.dependent_care_credit
  ])
  state.define('total_credits', credits)
  state.define('tax_and_credits', subtract(state.total_base_tax, state.total_credits))

  log_value('line 54 total credits', state.total_credits)
  log_value('line 55', state.tax_and_credits)
  return state


compute_dependent_care_credit = (state) ->

  log = (prop, val) ->
    log_value("2441 -- #{prop}", val)
    return

  form = state['2441']
  form.adjusted_gross_income = state.adjusted_gross_income
  form = Form_2441.create(form).compute()
  log('line 4', form.my_earned_income)
  log('line 5', form.spouse_earned_income)
  log('line 6', form.max_amount)
  log('line 8', form.multiplier)
  log('line 9', form.tentative_credit)
  log('line 10', state.total_base_tax)
  log('line 11 Dependent Care Credit', form.credit)
  return state


compute_total_tax = (state) ->
  taxes = [state.tax_and_credits]
  for own name, amount of state.other_taxes
    taxes.push(amount)
    log_value(name, amount)

  total = sum(taxes)
  return assign_and_log(state, 'total_tax', total)


compute_payments = (state) ->
  payments = []
  for own name, amount of state['1040'].payments
    payments.push(amount)
    log_value(name, amount)

  total = sum(payments)
  return assign_and_log(state, 'total_payments', total)


compute_tax = (state) ->
  tax = subtract(state.total_tax, state.total_payments)
  return assign_and_log(state, 'tax', tax)


read_form = (state) ->
  form = require(state.form_path)
  utils =
    sum: sum
    subtract: subtract

  state.define('1040', Object.create(null))
  form['1040'](state['1040'], utils)

  state.define('schedule_c', Object.create(null))
  form['Schedule C'](state.schedule_c, utils)

  state.define('2441', Object.create(null))
  form['2441'](state['2441'], utils)

  return state


assign_and_log = (state, prop, val) ->
  state.define(prop, val)
  log_value(prop, val)
  return state


log_value = (prop, val) ->
  print "#{prop}: #{val}"
