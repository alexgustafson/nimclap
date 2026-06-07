import ../host
import ../plugin

let extLatency*: cstring = cstring"clap.latency"

type
  PluginLatency* {.bycopy.} = object
    get*: proc(plugin: ptr Plugin): uint32 {.cdecl.}
      ## Returns the plugin latency in samples.
      ## `[main-thread & (being-activated | active)]`

  HostLatency* {.bycopy.} = object
    changed*: proc(host: ptr Host) {.cdecl.}
      ## Tell the host that the latency changed.
      ## The latency is only allowed to change during `Plugin.activate`.
      ## If the plugin is activated, call `Host.requestRestart`.
      ## `[main-thread & being-activated]`
