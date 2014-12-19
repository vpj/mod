    Mod = {}
    _self = null

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

##Register a module

    Mod.set = (name, module) ->
     if modules[name]?
      throw new Error "Module #{name} already registered"

     modules[name] = module

     if initializeCalled and not running
      try
       running = true
       run()
      catch e
       running = false
       console.log 'Set', name
       console.error e.message

     if everythingLoaded
      console.log 'All dependencies are met'
      for cb in loaded
       cb()

##Register callbacks to run after everything loads

    Mod.onLoad = (callback) ->
     loaded.push callback

##Require modules

    Mod.require = ->
     if arguments.length < 1
      throw new Error 'Mod.require needs at least on argument'
     else if arguments.length is 2 and Array.isArray arguments[0]
      list = arguments[0]
      callback = arguments[1]
     else
      callback = arguments[arguments.length - 1]
      list = []
      for i in [0...arguments.length - 1]
       list.push arguments[i]

     if (typeof callback) isnt 'function'
      throw new Error 'Last argument of Mod.require should be a function'
     for l in list
      if (typeof l) isnt 'string'
       throw new Error 'Required namespaces should be strings'

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
       throw new Error s

     everythingLoaded = true

    Mod.initialize = ->
     console.log 'init'
     initializeCalled = true

     try
      running = true
      run()
     catch e
      console.error e.message

     running = false
     if everythingLoaded
      console.log 'All dependencies are met'
      for cb in loaded
       cb()

