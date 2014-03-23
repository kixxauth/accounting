ScheduleC = require './schedule_c_model'

class ScheduleCPerformer

  perform: (form) ->
    schedule_c = ScheduleC.create(form.schedule_c).compute()
    return form.update('schedule_c', schedule_c)

  @create = ->
    performer = new @()
    return performer.perform

module.exports = ScheduleCPerformer
