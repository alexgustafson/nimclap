import ../../private/std, ../../private/macros

##  Use it to retrieve const clap_plugin_invalidation_factory_t* from
##  clap_plugin_entry.get_factory()

let pluginInvalidationFactoryId*: UncheckedArray[char] =
  "clap.plugin-invalidation-factory/1"

type PluginInvalidationSource* {.bycopy.} = object
  ##  Directory containing the file(s) to scan, must be absolute
  directory*: cstring
  ##  globing pattern, in the form *.dll
  filenameGlob*: cstring
  ##  should the directory be scanned recursively?
  recursiveScan*: bool

##  Used to figure out when a plugin needs to be scanned again.
##  Imagine a situation with a single entry point: my-plugin.clap which then scans itself
##  a set of "sub-plugins". New plugin may be available even if my-plugin.clap file doesn't change.
##  This interfaces solves this issue and gives a way to the host to monitor additional files.

type PluginInvalidationFactory* {.bycopy.} = object
  ##  Get the number of invalidation source.
  count*: proc(factory: ptr PluginInvalidationFactory): uint32 {.cdecl.}
  ##  Get the invalidation source by its index.
  ##  [thread-safe]
  get*: proc(
    factory: ptr PluginInvalidationFactory, index: uint32
  ): ptr PluginInvalidationSource {.cdecl.}
  ##  In case the host detected a invalidation event, it can call refresh() to let the
  ##  plugin_entry update the set of plugins available.
  ##  If the function returned false, then the plugin needs to be reloaded.
  refresh*: proc(factory: ptr PluginInvalidationFactory): bool {.cdecl.}
