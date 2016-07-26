    Mod = {}
    SELF = null
    DEBUG = false

    if console?.log?
     LOG = console.log.bind console
    else
     LOG = -> null

If **node.js**

    if global?
     global.Mod = Mod
     SELF = global

If **browser**

    else
     @Mod = Mod
     SELF = this

    MODULES = {}
    CALLBACKS = []
    ON_LOADED = []
    INITIALIZED = false
    LOADING_COMPLETED = false
    LOADING = 0

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

     if DEBUG
      LOG "MOD: Set - #{name}"

     _run()
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

     return if not INITIALIZED
     _run()
     _onLoaded()

##Initialize modules

    _onLoaded = ->
     return unless LOADING_COMPLETED and LOADING is 0

     if DEBUG
      LOG "MOD: All dependencies are met"
     for cb in ON_LOADED
      cb()

    _loadCallback = (callback, modules) ->
     callback.called = true
     LOADING++
     setTimeout ->
      callback.callback.apply SELF, modules
      LOADING--
      _onLoaded()
     , 0

    _run = ->
     try
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
        _loadCallback cb, list
        nCall++

      if nUncalled isnt 0 and nCall is 0
       todo = {}
       for cb in CALLBACKS when cb.called is false
        for name in cb.list when not MODULES[name]?
         todo[name] = true

       err = "Dependencies: #{(n for n of todo).join ', '}"
       throw new ModError err
      else if DEBUG and nUncalled > nCall
       todo = {}
       for cb in CALLBACKS when cb.called is false
        for name in cb.list when not MODULES[name]?
         todo[name] = true

       err = "Dependencies: #{(n for n of todo).join ', '}"
       LOG err


      if nUncalled is nCall
       LOADING_COMPLETED = true
     catch e
      if e instanceof ModError
       if DEBUG
        LOG "MOD: Error - #{e.message}"
      else
       throw e

    Mod.debug = (d = true) ->
     DEBUG = d

    Mod.initialize = ->
     INITIALIZED = true

     _run()
     _onLoaded()

