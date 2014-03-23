FormDataPerformer = require './form_data_performer'
ScheduleCPerformer = require './schedule_c_performer'

class ComputePersonalTaxPerformer
  perform: ->
    promise = FormDataPerformer.invoke()
      .then(ScheduleCPerformer.create())
    return promise

  @create = (opts) ->
    performer = new @()
    return performer.perform

module.exports = ComputePersonalTaxPerformer
