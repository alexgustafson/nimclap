import
  ../plugin, ../stream

var CLAP_EXT_STATE*: UncheckedArray[char] = "clap.state"

type
  ClapPluginStateT* {.bycopy.} = object
    save*: proc (plugin: ptr ClapPluginT; stream: ptr ClapOstreamT): bool ##  Saves the plugin state into stream.
                                                                 ##  Returns true if the state was correctly saved.
                                                                 ##  [main-thread]
    ##  Loads the plugin state from stream.
    ##  Returns true if the state was correctly restored.
    ##  [main-thread]
    load*: proc (plugin: ptr ClapPluginT; stream: ptr ClapIstreamT): bool

  ClapHostStateT* {.bycopy.} = object
    markDirty*: proc (host: ptr ClapHostT) ##  Tell the host that the plugin state has changed and should be saved again.
                                      ##  If a parameter value changes, then it is implicit that the state is dirty.
                                      ##  [main-thread]

