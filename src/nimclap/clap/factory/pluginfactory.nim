import host
import
  ../plugin

##  Use it to retrieve const clap_plugin_factory_t* from
##  clap_plugin_entry.get_factory()

let CLAP_PLUGIN_FACTORY_ID*: UncheckedArray[char] = "clap.plugin-factory"

##  Every method must be thread-safe.
##  It is very important to be able to scan the plugin as quickly as possible.
##
##  The host may use clap_plugin_invalidation_factory to detect filesystem changes
##  which may change the factory's content.

type
  clap_plugin_factory* {.bycopy.} = object
    ##  Get the number of plugins available.
    ##  [thread-safe]
    get_plugin_count*: proc (factory: ptr clap_plugin_factory): uint32 {.cdecl.}
    ##  Retrieves a plugin descriptor by its index.
    ##  Returns null in case of error.
    ##  The descriptor must not be freed.
    ##  [thread-safe]
    get_plugin_descriptor*: proc (factory: ptr clap_plugin_factory; index: uint32): ptr clap_plugin_descriptor {.
        cdecl.}
    ##  Create a clap_plugin by its plugin_id.
    ##  The returned pointer must be freed by calling plugin->destroy(plugin);
    ##  The plugin is not allowed to use the host callbacks in the create method.
    ##  Returns null in case of error.
    ##  [thread-safe]
    create_plugin*: proc (factory: ptr clap_plugin_factory; host: ptr clap_host;
                        plugin_id: cstring): ptr clap_plugin {.cdecl.}

