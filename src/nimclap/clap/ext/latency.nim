import ../host
import ../plugin

let extLatency*: cstring = cstring"clap.latency"

type
  PluginLatency* {.bycopy.} = object
    ##  Returns the plugin latency in samples.
    ##  [main-thread & (being-activated | active)]
    get*: proc(plugin: ptr Plugin): uint32 {.cdecl.}

  HostLatency* {.bycopy.} = object
    ##  Tell the host that the latency changed.
    ##  The latency is only allowed to change during plugin->activate.
    ##  If the plugin is activated, call host->request_restart()
    ##  [main-thread & being-activated]
    changed*: proc(host: ptr Host) {.cdecl.}
