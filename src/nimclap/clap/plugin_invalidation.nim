import
  private/std, private/macros

type
  ClapPluginInvalidationSourceT* {.bycopy.} = object
    directory*: cstring        ##  Directory containing the file(s) to scan, must be absolute
    ##  globing pattern, in the form *.dll
    filenameGlob*: cstring     ##  should the directory be scanned recursively?
    recursiveScan*: bool


var CLAP_PLUGIN_INVALIDATION_FACTORY_ID*: UncheckedArray[char] = "clap.plugin-invalidation-factory/draft0"

##  Used to figure out when a plugin needs to be scanned again.
##  Imagine a situation with a single entry point: my-plugin.clap which then scans itself
##  a set of "sub-plugins". New plugin may be available even if my-plugin.clap file doesn't change.
##  This interfaces solves this issue and gives a way to the host to monitor additional files.

type
  ClapPluginInvalidationFactoryT* {.bycopy.} = object
    count*: proc (factory: ptr ClapPluginInvalidationFactory): uint32T ##  Get the number of invalidation source.
    ##  Get the invalidation source by its index.
    ##  [thread-safe]
    get*: proc (factory: ptr ClapPluginInvalidationFactory; index: uint32T): ptr ClapPluginInvalidationSourceT ##  In case the host detected a invalidation event, it can call refresh() to let the
                                                                                                      ##  plugin_entry update the set of plugins available.
                                                                                                      ##  If the function returned false, then the plugin needs to be reloaded.
    refresh*: proc (factory: ptr ClapPluginInvalidationFactory): bool

