exports.usage = "personal_taxes.coffee"

exports.options =
  form:
    description: "The path to the input form."
    required: yes

exports.help = """
Compute tax forms and output results.
"""

ComputePersonalTaxPerformer = require './lib/compute_personal_tax_performer'

exports.main = (opts) ->
  Promise.cast(ComputePersonalTaxPerformer.create(opts)())
    .then(result_printer(opts))
    .catch(LIB.fail)
  return


result_printer = (opts) ->
  print_results = (res) ->
    print 'RESULTS', res
    return
  return print_results
