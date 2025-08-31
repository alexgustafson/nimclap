import ../host
import ../plugin

##  Use it to retrieve const clap_plugin_factory_t* from
##  clap_plugin_entry.get_factory()

let pluginFactoryId*: cstring = cstring"clap.plugin-factory"

##  Every method must be thread-safe.
##  It is very important to be able to scan the plugin as quickly as possible.
##
##  The host may use clap_plugin_invalidation_factory to detect filesystem changes
##  which may change the factory's content.

type PluginFactory* {.bycopy.} = object
  ##  Get the number of plugins available.
  ##  [thread-safe]
  getPluginCount*: proc(factory: ptr PluginFactory): uint32 {.cdecl.}
  ##  Retrieves a plugin descriptor by its index.
  ##  Returns null in case of error.
  ##  The descriptor must not be freed.
  ##  [thread-safe]
  getPluginDescriptor*:
    proc(factory: ptr PluginFactory, index: uint32): ptr PluginDescriptor {.cdecl.}
  ##  Create a clap_plugin by its plugin_id.
  ##  The returned pointer must be freed by calling plugin->destroy(plugin);
  ##  The plugin is not allowed to use the host callbacks in the create method.
  ##  Returns null in case of error.
  ##  [thread-safe]
  createPlugin*: proc(
    factory: ptr PluginFactory, host: ptr Host, pluginId: cstring
  ): ptr Plugin {.cdecl.}
