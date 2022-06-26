import
  plugin

var CLAP_PLUGIN_FACTORY_ID*: UncheckedArray[char] = "clap.plugin-factory"

##  Every methods must be thread-safe.
##  It is very important to be able to scan the plugin as quickly as possible.
##
##  If the content of the factory may change due to external events, like the user installed

type
  ClapPluginFactoryT* {.bycopy.} = object
    getPluginCount*: proc (factory: ptr ClapPluginFactory): uint32T ##  Get the number of plugins available.
                                                              ##  [thread-safe]
    ##  Retrieves a plugin descriptor by its index.
    ##  Returns null in case of error.
    ##  The descriptor must not be freed.
    ##  [thread-safe]
    getPluginDescriptor*: proc (factory: ptr ClapPluginFactory; index: uint32T): ptr ClapPluginDescriptorT ##  Create a clap_plugin by its plugin_id.
                                                                                                  ##  The returned pointer must be freed by calling plugin->destroy(plugin);
                                                                                                  ##  The plugin is not allowed to use the host callbacks in the create method.
                                                                                                  ##  Returns null in case of error.
                                                                                                  ##  [thread-safe]
    createPlugin*: proc (factory: ptr ClapPluginFactory; host: ptr ClapHostT;
                       pluginId: cstring): ptr ClapPluginT

