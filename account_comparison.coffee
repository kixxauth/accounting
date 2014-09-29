exports.usage = "account_comparison.coffee"

exports.help = """
Compute and print a comparison between two investment options.
"""

ACC = require './lib/'

exports.main = (opts) ->
  current529 = new Plan529
    year: 2014
    pre_taxrate: 0
    taxrate: 0.24
    return_rate: 0.05

  currentInvestment = new Investments
    year: 2014
    pre_taxrate: 0
    taxrate: 0.24
    return_rate: 0.07

  contribution = 5000

  LIB.each LIB.range(1, 13), (i) ->
    current529 = current529.computeYear(contribution)
    currentInvestment = currentInvestment.computeYear(contribution)
    line = """
    #{current529.year}    #{current529.balance}    #{currentInvestment.balance}
    """
    print line


class Plan529
  constructor: (spec = {}) ->
    @year = ACC.ensure_number(spec.year)
    @pre_taxrate = ACC.ensure_number(spec.pre_taxrate)
    @taxrate = ACC.ensure_number(spec.taxrate)
    @return_rate = ACC.ensure_number(spec.return_rate)
    @balance = ACC.ensure_number(spec.balance)
    @contribution = ACC.ensure_number(spec.contribution)

  computeYear: (contribution = @contribution) ->
    contribution = @deductPretax(contribution)
    balance = @addEarnings(ACC.sum(@balance, contribution))
    new_year = new Plan529
      year         : @year + 1
      taxrate      : @taxrate
      return_rate  : @return_rate
      balance      : balance
      contribution : contribution
    return new_year

  deductPretax: (contribution) ->
    deduction = ACC.multiply(contribution, @pre_taxrate)
    return ACC.subtract(contribution, deduction)

  addEarnings: (balance) ->
    earnings = ACC.multiply(balance, @return_rate)
    return ACC.sum(balance, earnings)

  withdrawl: ->
    return @balance


class Investments
  constructor: (spec = {}) ->
    @year = ACC.ensure_number(spec.year)
    @pre_taxrate = ACC.ensure_number(spec.pre_taxrate)
    @taxrate = ACC.ensure_number(spec.taxrate)
    @return_rate = ACC.ensure_number(spec.return_rate)
    @balance = ACC.ensure_number(spec.balance)
    @contribution = ACC.ensure_number(spec.contribution)

  computeYear: (contribution = @contribution) ->
    contribution = @deductPretax(contribution)
    balance = @addEarnings(ACC.sum(@balance, contribution))
    new_year = new Investments
      year         : @year + 1
      taxrate      : @taxrate
      return_rate  : @return_rate
      balance      : balance
      contribution : contribution
    return new_year

  deductPretax: (contribution) ->
    deduction = ACC.multiply(contribution, @pre_taxrate)
    return ACC.subtract(contribution, deduction)

  addEarnings: (balance) ->
    earnings = ACC.multiply(balance, @return_rate)
    taxes = ACC.multiply(earnings, @taxrate)
    return ACC.sum(balance, ACC.subtract(earnings, taxes))

  withdrawl: ->
    return @balance
