import
  ../plugin

let CLAP_EXT_RENDER*: UncheckedArray[char] = "clap.render"

const                         ##  Default setting, for "realtime" processing
  CLAP_RENDER_REALTIME* = 0     ##  For processing without realtime pressure
                         ##  The plugin may use more expensive algorithms for higher sound quality.
  CLAP_RENDER_OFFLINE* = 1

type
  clap_plugin_render_mode* = int32

##  The render extension is used to let the plugin know if it has "realtime"
##  pressure to process.
##
##  If this information does not influence your rendering code, then don't
##  implement this extension.

type
  clap_plugin_render* {.bycopy.} = object
    ##  Returns true if the plugin has a hard requirement to process in real-time.
    ##  This is especially useful for plugin acting as a proxy to an hardware device.
    ##  [main-thread]
    has_hard_realtime_requirement*: proc (plugin: ptr clap_plugin): bool {.cdecl.}
    ##  Returns true if the rendering mode could be applied.
    ##  [main-thread]
    set*: proc (plugin: ptr clap_plugin; mode: clap_plugin_render_mode): bool {.cdecl.}

