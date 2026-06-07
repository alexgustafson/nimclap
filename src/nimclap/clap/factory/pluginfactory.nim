import ../host
import ../plugin

let pluginFactoryId*: cstring = cstring"clap.plugin-factory"
  ## Use it to retrieve a `PluginFactory` pointer from `PluginEntry.getFactory`.

type PluginFactory* {.bycopy.} = object
  ## Every method must be thread-safe.
  ## It is very important to be able to scan the plugin as quickly as possible.
  ##
  ## The host may use `PluginInvalidationFactory` to detect filesystem changes
  ## which may change the factory's content.
  getPluginCount*: proc(factory: ptr PluginFactory): uint32 {.cdecl.}
    ## Get the number of plugins available.
    ## `[thread-safe]`
  getPluginDescriptor*:
    proc(factory: ptr PluginFactory, index: uint32): ptr PluginDescriptor {.cdecl.}
    ## Retrieves a plugin descriptor by its index.
    ## Returns nil in case of error.
    ## The descriptor must not be freed.
    ## `[thread-safe]`
  createPlugin*: proc(
    factory: ptr PluginFactory, host: ptr Host, pluginId: cstring
  ): ptr Plugin {.cdecl.}
    ## Create a `Plugin` by its `pluginId`.
    ## The returned pointer must be freed by calling `Plugin.destroy`.
    ## The plugin is not allowed to use the host callbacks in the create method.
    ## Returns nil in case of error.
    ## `[thread-safe]`
