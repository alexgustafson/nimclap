import ../host
import ../plugin, ../stream

## State management.
##
## Plugins can implement this extension to save and restore both parameter
## values and non-parameter state. This is used to persist a plugin's state
## between project reloads, when duplicating and copying plugin instances, and
## for host-side preset management.
##
## If you need to know if the save/load operation is meant for duplicating a
## plugin instance, for saving/loading a plugin preset or while saving/loading
## the project then consider implementing `extStateContext` in addition to
## `extState`.

let extState*: cstring = cstring"clap.state"

type
  PluginState* {.bycopy.} = object
    save*: proc(plugin: ptr Plugin, stream: ptr Ostream): bool {.cdecl.}
      ## Saves the plugin state into `stream`.
      ## Returns true if the state was correctly saved.
      ## `[main-thread]`
    load*: proc(plugin: ptr Plugin, stream: ptr Istream): bool {.cdecl.}
      ## Loads the plugin state from `stream`.
      ## Returns true if the state was correctly restored.
      ## `[main-thread]`

  HostState* {.bycopy.} = object
    markDirty*: proc(host: ptr Host) {.cdecl.}
      ## Tell the host that the plugin state has changed and should be saved
      ## again.
      ## If a parameter value changes, then it is implicit that the state is
      ## dirty.
      ## `[main-thread]`
