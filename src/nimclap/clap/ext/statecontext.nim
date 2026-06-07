import ../plugin, ../stream

## Extended state handling.
##
## This extension lets the host save and load the plugin state with different
## semantics depending on the context.
##
## Briefly, when loading a preset or duplicating a device, the plugin may want
## to partially load the state and initialize certain things differently, like
## handling limited resources or fixed connections to external hardware
## resources.
##
## Save and Load operations may have a different context.
## All three operations should be equivalent:
## 1. `PluginStateContext.load(PluginState.save(), contextForPreset)`
## 2. `PluginState.load(PluginStateContext.save(contextForPreset))`
## 3. `PluginStateContext.load(`
##        `PluginStateContext.save(contextForPreset),`
##        `contextForPreset)`
##
## If in doubt, fallback to `PluginState`.
##
## If the plugin implements `extStateContext` then it is mandatory to also
## implement `extState`.
##
## It is unspecified which context is equivalent to `PluginState.save` /
## `PluginState.load`.

let extStateContext*: cstring = cstring"clap.state-context/2"

type PluginStateContextType* {.pure.} = enum
  contextForPreset = 1
    ## Suitable for storing and loading a state as a preset.
  contextForDuplicate = 2
    ## Suitable for duplicating a plugin instance.
  contextForProject = 3
    ## Suitable for storing and loading a state within a project/song.

type PluginStateContext* {.bycopy.} = object
  save*:
    proc(plugin: ptr Plugin, stream: ptr Ostream, contextType: uint32): bool {.cdecl.}
    ## Saves the plugin state into `stream`, according to `contextType`.
    ## Returns true if the state was correctly saved.
    ##
    ## Note that the result may be loaded by both `PluginState.load` and
    ## `PluginStateContext.load`.
    ## `[main-thread]`
  load*:
    proc(plugin: ptr Plugin, stream: ptr Istream, contextType: uint32): bool {.cdecl.}
    ## Loads the plugin state from `stream`, according to `contextType`.
    ## Returns true if the state was correctly restored.
    ##
    ## Note that the state may have been saved by `PluginState.save` or
    ## `PluginStateContext.save` with a different `contextType`.
    ## `[main-thread]`
