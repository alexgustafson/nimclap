import
  ../../private/std, ../../private/macros

##  Use it to retrieve const clap_plugin_invalidation_factory_t* from
##  clap_plugin_entry.get_factory()

let CLAP_PLUGIN_INVALIDATION_FACTORY_ID*: cstring = cstring"clap.plugin-invalidation-factory/draft0"

type
  clap_plugin_invalidation_source* {.bycopy.} = object
    ##  Directory containing the file(s) to scan, must be absolute
    directory*: cstring
    ##  globing pattern, in the form *.dll
    filename_glob*: cstring
    ##  should the directory be scanned recursively?
    recursive_scan*: bool


##  Used to figure out when a plugin needs to be scanned again.
##  Imagine a situation with a single entry point: my-plugin.clap which then scans itself
##  a set of "sub-plugins". New plugin may be available even if my-plugin.clap file doesn't change.
##  This interfaces solves this issue and gives a way to the host to monitor additional files.

type
  clap_plugin_invalidation_factory* {.bycopy.} = object
    ##  Get the number of invalidation source.
    count*: proc (factory: ptr clap_plugin_invalidation_factory): uint32 {.cdecl.}
    ##  Get the invalidation source by its index.
    ##  [thread-safe]
    get*: proc (factory: ptr clap_plugin_invalidation_factory; index: uint32): ptr clap_plugin_invalidation_source {.
        cdecl.}
    ##  In case the host detected a invalidation event, it can call refresh() to let the
    ##  plugin_entry update the set of plugins available.
    ##  If the function returned false, then the plugin needs to be reloaded.
    refresh*: proc (factory: ptr clap_plugin_invalidation_factory): bool {.cdecl.}

