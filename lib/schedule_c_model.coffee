class ScheduleC

  compute: ->
    return ScheduleC.create()

  @create = () ->
    model = new @()
    return model

compute_income = (model) ->
  {receipts, returns} = model.attributes
