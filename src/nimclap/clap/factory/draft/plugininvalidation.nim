import ../../private/std, ../../private/macros

let pluginInvalidationFactoryId*: cstring =
  cstring"clap.plugin-invalidation-factory/1"
  ## Use it to retrieve a `PluginInvalidationFactory` pointer from
  ## `PluginEntry.getFactory`.

type PluginInvalidationSource* {.bycopy.} = object
  directory*: cstring
    ## Directory containing the file(s) to scan, must be absolute.
  filenameGlob*: cstring
    ## Globbing pattern, in the form `*.dll`.
  recursiveScan*: bool
    ## Should the directory be scanned recursively?

type PluginInvalidationFactory* {.bycopy.} = object
  ## Used to figure out when a plugin needs to be scanned again.
  ## Imagine a situation with a single entry point: `my-plugin.clap` which then
  ## scans itself a set of "sub-plugins". New plugin may be available even if the
  ## `my-plugin.clap` file doesn't change.
  ## This interface solves this issue and gives a way to the host to monitor
  ## additional files.
  count*: proc(factory: ptr PluginInvalidationFactory): uint32 {.cdecl.}
    ## Get the number of invalidation source.
  get*: proc(
    factory: ptr PluginInvalidationFactory, index: uint32
  ): ptr PluginInvalidationSource {.cdecl.}
    ## Get the invalidation source by its index.
    ## `[thread-safe]`
  refresh*: proc(factory: ptr PluginInvalidationFactory): bool {.cdecl.}
    ## In case the host detected an invalidation event, it can call `refresh` to
    ## let the `PluginEntry` update the set of plugins available.
    ## If the function returned false, then the plugin needs to be reloaded.
