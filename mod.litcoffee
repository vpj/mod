    Mod = {}
    _self = null

    if console?.log?
     LOG = console.log.bind console
    else
     LOG = -> null

    if console?.error?
     ERROR_LOG = console.error.bind console
    else
     ERROR_LOG = -> null

If **node.js**

    if GLOBAL?
     GLOBAL.Mod = Mod
     _self = GLOBAL

If **browser**

    else
     @Mod = Mod
     _self = this

    modules = {}
    callbacks = []
    loaded = []
    initializeCalled = false
    everythingLoaded = false
    running = false

    class ModError extends Error
     constructor: (message) ->
      super message
      @message = message

##Register a module

    Mod.set = (name, module) ->
     if modules[name]?
      throw new ModError "Module #{name} already registered"

     modules[name] = module

     if initializeCalled and not running
      try
       running = true
       run()
      catch e
       running = false
       LOG 'Set', name
       if e instanceof ModError
        ERROR_LOG e.message
       else
        throw e

     if everythingLoaded
      LOG 'All dependencies are met'
      for cb in loaded
       cb()

##Register callbacks to run after everything loads

    Mod.onLoad = (callback) ->
     loaded.push callback

##Require modules

    Mod.require = ->
     if arguments.length < 1
      throw new ModError 'Mod.require needs at least on argument'
     else if arguments.length is 2 and Array.isArray arguments[0]
      list = arguments[0]
      callback = arguments[1]
     else
      callback = arguments[arguments.length - 1]
      list = []
      for i in [0...arguments.length - 1]
       list.push arguments[i]

     if (typeof callback) isnt 'function'
      throw new ModError 'Last argument of Mod.require should be a function'
     for l in list
      if (typeof l) isnt 'string'
       throw new ModError 'Required namespaces should be strings'

     callbacks.push
      callback: callback
      list: list
      called: false

##Initialize modules


    run = ->
     everythingLoaded = false

     while true
      n = 0
      nC = 0
      for cb in callbacks when cb.called is false
       n++
       k = parseInt k
       list = []
       satis = true
       for name in cb.list
        if modules[name]?
         list.push modules[name]
        else
         satis = false
         break

       if satis is true
        cb.called = true
        cb.callback.apply _self, list
        nC++

      break if n is 0

      if n isnt 0 and nC is 0
       todo = {}
       s = "Cyclic dependancy: "
       for cb in callbacks when cb.called is false
        for name in cb.list when not modules[name]?
         todo[name] = true

       first = ""
       for name of todo
        s += "#{first}#{name}"
        first = ", "
       throw new ModError s

     everythingLoaded = true

    Mod.initialize = ->
     LOG 'init'
     initializeCalled = true

     try
      running = true
      run()
     catch e
      if e instanceof ModError
       ERROR_LOG e.message
      else
       throw e

     running = false
     if everythingLoaded
      LOG 'All dependencies are met'
      for cb in loaded
       cb()

