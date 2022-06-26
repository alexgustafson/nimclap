import
  ../plugin

var CLAP_EXT_LATENCY*: UncheckedArray[char] = "clap.latency"

##  The audio ports scan has to be done while the plugin is deactivated.

type
  ClapPluginLatencyT* {.bycopy.} = object
    get*: proc (plugin: ptr ClapPluginT): uint32T ##  Returns the plugin latency.
                                            ##  [main-thread]

  ClapHostLatencyT* {.bycopy.} = object
    changed*: proc (host: ptr ClapHostT) ##  Tell the host that the latency changed.
                                    ##  The latency is only allowed to change if the plugin is deactivated.
                                    ##  If the plugin is activated, call host->request_restart()
                                    ##  [main-thread]

