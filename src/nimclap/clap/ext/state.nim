import ../host
import ../plugin, ../stream

##  @page State
##  @brief state management
##
##  Plugins can implement this extension to save and restore both parameter
##  values and non-parameter state. This is used to persist a plugin's state
##  between project reloads, when duplicating and copying plugin instances, and
##  for host-side preset management.
##
##  If you need to know if the save/load operation is meant for duplicating a plugin
##  instance, for saving/loading a plugin preset or while saving/loading the project
##  then consider implementing CLAP_EXT_STATE_CONTEXT in addition to CLAP_EXT_STATE.

let extState*: cstring = cstring"clap.state"

type
  PluginState* {.bycopy.} = object
    ##  Saves the plugin state into stream.
    ##  Returns true if the state was correctly saved.
    ##  [main-thread]
    save*: proc(plugin: ptr Plugin, stream: ptr Ostream): bool {.cdecl.}
    ##  Loads the plugin state from stream.
    ##  Returns true if the state was correctly restored.
    ##  [main-thread]
    load*: proc(plugin: ptr Plugin, stream: ptr Istream): bool {.cdecl.}

  HostState* {.bycopy.} = object
    ##  Tell the host that the plugin state has changed and should be saved again.
    ##  If a parameter value changes, then it is implicit that the state is dirty.
    ##  [main-thread]
    markDirty*: proc(host: ptr Host) {.cdecl.}
