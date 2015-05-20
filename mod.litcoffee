    Mod = {}
    SELF = null

    if console?.log?
     LOG = console.log.bind console
    else
     LOG = -> null

If **node.js**

    if GLOBAL?
     GLOBAL.Mod = Mod
     SELF = GLOBAL

If **browser**

    else
     @Mod = Mod
     SELF = this

    MODULES = {}
    CALLBACKS = []
    ON_LOADED = []
    INITIALIZED = false
    LOADING_COMPLETED = false

    class ModError extends Error
     constructor: (message) ->
      super message
      @message = message

##Register a module

    Mod.set = (name, module) ->
     if MODULES[name]?
      throw new ModError "Module #{name} already registered"

     MODULES[name] = module

     return if not INITIALIZED

     try
      run()
     catch e
      LOG "MOD: Set - #{name}"
      if e instanceof ModError
       LOG "MOD: Error - #{e.message}"
      else
       throw e

    _onLoaded()

##Register callbacks to run after everything loads

    Mod.onLoad = (callback) ->
     ON_LOADED.push callback

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

     CALLBACKS.push
      callback: callback
      list: list
      called: false

##Initialize modules
    _onLoaded = ->
     return if not LOADING_COMPLETED

     LOG "MOD: All dependencies are met"
     for cb in ON_LOADED
      cb()

    loadCallback = (callback, modules) ->
     callback.called = true
     setTimeout ->
      callback.callback.apply SELF, modules
     , 0

    run = ->
     LOADING_COMPLETED = false

     nUncalled = 0
     nCall = 0
     for cb in CALLBACKS when cb.called is false
      nUncalled++
      list = []
      satis = true
      for name in cb.list
       if MODULES[name]?
        list.push MODULES[name]
       else
        satis = false
        break

      if satis is true
       loadCallback cb, list
       nCall++

     if nUncalled isnt 0 and nCall is 0
      todo = {}
      s = "Cyclic dependancy: "
      for cb in CALLBACKS when cb.called is false
       for name in cb.list when not MODULES[name]?
        todo[name] = true

      first = ""
      for name of todo
       s += "#{first}#{name}"
       first = ", "
      throw new ModError s

     if nUncalled is nCall
      LOADING_COMPLETED = true

    Mod.initialize = ->
     INITIALIZED = true

     try
      run()
     catch e
      if e instanceof ModError
       LOG "MOD: Error - #{e.message}"
      else
       throw e

     _onLoaded()

