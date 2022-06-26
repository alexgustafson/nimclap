import
  ../plugin

var CLAP_EXT_RENDER*: UncheckedArray[char] = "clap.render"

const                         ##  Default setting, for "realtime" processing
  CLAP_RENDER_REALTIME* = 0     ##  For processing without realtime pressure
                         ##  The plugin may use more expensive algorithms for higher sound quality.
  CLAP_RENDER_OFFLINE* = 1

type
  ClapPluginRenderMode* = int32T

##  The render extension is used to let the plugin know if it has "realtime"
##  pressure to process.
##
##  If this information does not influence your rendering code, then don't
##  implement this extension.

type
  ClapPluginRenderT* {.bycopy.} = object
    hasHardRealtimeRequirement*: proc (plugin: ptr ClapPluginT): bool ##  Returns true if the plugin has an hard requirement to process in real-time.
                                                                ##  This is especially useful for plugin acting as a proxy to an hardware device.
                                                                ##  [main-thread]
    ##  Returns true if the rendering mode could be applied.
    ##  [main-thread]
    set*: proc (plugin: ptr ClapPluginT; mode: ClapPluginRenderMode): bool

