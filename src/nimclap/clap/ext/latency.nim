import ../host
import
  ../plugin

let CLAP_EXT_LATENCY*: cstring = cstring"clap.latency"

##  The audio ports scan has to be done while the plugin is deactivated.

type
  clap_plugin_latency* {.bycopy.} = object
    ##  Returns the plugin latency.
    ##  [main-thread]
    get*: proc (plugin: ptr clap_plugin): uint32 {.cdecl.}

  clap_host_latency* {.bycopy.} = object
    ##  Tell the host that the latency changed.
    ##  The latency is only allowed to change if the plugin is deactivated.
    ##  If the plugin is activated, call host->request_restart()
    ##  [main-thread]
    changed*: proc (host: ptr clap_host) {.cdecl.}

