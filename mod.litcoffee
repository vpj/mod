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

##Register a module

    Mod.set = (name, module) ->
     if modules[name]?
      throw new Error "Module #{name} already registered"

     modules[name] = module

##Register callbacks to run after everything loads

    Mod.onLoad = (callback) ->
     loaded.push callback

##Require modules

    Mod.require = (list, callback) ->
     map = {}
     for k in list
      map[k] = true

     callbacks.push
      callback: callback
      list: list
      called: false

##Initialize modules

    Mod.initialize = ->
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
       for cb in callbacks
        for name in cb.list
         todo[name] = true

       first = ""
       for name of todo
        s += "#{first}#{name}"
        first = ", "
       throw s

     console.log "Initialized"
     for cb in loaded
      cb.call _self

