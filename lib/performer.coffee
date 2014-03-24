class Performer

  constructor: ->
    for name, method of @
      if name isnt 'constructor' and name isnt 'initialize' and LIB.isFunction(method)
        @[name] = LIB.bind(method, @)

    @initialize.apply(@, arguments) if LIB.isFunction(@initialize)


module.exports = Performer
