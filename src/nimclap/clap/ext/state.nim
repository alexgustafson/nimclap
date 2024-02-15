import ../host
import
  ../plugin, ../stream

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

let CLAP_EXT_STATE*: cstring = cstring"clap.state"

type
  clap_plugin_state* {.bycopy.} = object
    ##  Saves the plugin state into stream.
    ##  Returns true if the state was correctly saved.
    ##  [main-thread]
    save*: proc (plugin: ptr clap_plugin; stream: ptr clap_ostream): bool {.cdecl.}
    ##  Loads the plugin state from stream.
    ##  Returns true if the state was correctly restored.
    ##  [main-thread]
    load*: proc (plugin: ptr clap_plugin; stream: ptr clap_istream): bool {.cdecl.}

  clap_host_state* {.bycopy.} = object
    ##  Tell the host that the plugin state has changed and should be saved again.
    ##  If a parameter value changes, then it is implicit that the state is dirty.
    ##  [main-thread]
    mark_dirty*: proc (host: ptr clap_host) {.cdecl.}

