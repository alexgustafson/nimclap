import ../plugin

let extRender*: cstring = cstring"clap.render"

const ##  Default setting, for "realtime" processing
  renderRealtime* = 0
    ##  For processing without realtime pressure
    ##  The plugin may use more expensive algorithms for higher sound quality.
  renderOffline* = 1

type PluginRenderMode* = int32

##  The render extension is used to let the plugin know if it has "realtime"
##  pressure to process.
##
##  If this information does not influence your rendering code, then don't
##  implement this extension.

type PluginRender* {.bycopy.} = object
  ##  Returns true if the plugin has a hard requirement to process in real-time.
  ##  This is especially useful for plugin acting as a proxy to an hardware device.
  ##  [main-thread]
  hasHardRealtimeRequirement*: proc(plugin: ptr Plugin): bool {.cdecl.}
  ##  Returns true if the rendering mode could be applied.
  ##  [main-thread]
  set*: proc(plugin: ptr Plugin, mode: PluginRenderMode): bool {.cdecl.}
