ACC = require './'

sum      = ACC.sum
subtract = ACC.subtract
multiply = ACC.multiply


class Schedule_C

  constructor: (@form) ->

  compute: ->
    @form.net_receipts = @net_receipts()
    @form.cost_of_goods_sold = @cost_of_goods_sold()
    @form.gross_profit = @gross_profit()
    @form.gross_income = @gross_income()
    @form.total_expenses = @total_expenses()
    @form.tentative_profit = @tentative_profit()
    @form.business_use_of_home = @business_use_of_home()
    @form.net_profit = @net_profit()
    return @form

  net_receipts: ->
   return subtract(@form.gross_receipts, @form.returns)

  cost_of_goods_sold: ->
    costs = []
    for own name, amount of @form.cost_of_goods_sold
      costs.push(amount)
    return sum(costs)

  gross_profit: ->
    return subtract(@form.net_receipts, @form.cost_of_goods_sold)

  gross_income: ->
    return sum(@form.gross_profit, @form.other_income)

  total_expenses: ->
    for own name, amount of @form.expenses.other_expenses
      @form.expenses[" other -- #{name}"] = amount
    delete @form.expenses.other_expenses
    expenses = []
    for own name, amount of @form.expenses
      expenses.push(amount)
    return sum(expenses)

  tentative_profit: ->
    subtract(@form.gross_income, @form.total_expenses)

  business_use_of_home: ->
    multiply(@form.home_business_use.used_square_footage, 5)

  net_profit: ->
    subtract(@form.tentative_profit, @form.business_use_of_home)

  # form.gross_receipts - Number
  # form.returns - Number
  # form.cost_of_goods_sold - Object hash.
  # form.other_income - Number
  # form.expenses - Object hash
  # form.home_business_use.used_square_footage
  @create = (form) ->
    return new Schedule_C(form)

exports.Schedule_C = Schedule_C
