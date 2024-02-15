import
  ../plugin

let CLAP_EXT_TIMER_SUPPORT*: cstring = cstring"clap.timer-support"

type
  clap_plugin_timer_support* {.bycopy.} = object
    ##  [main-thread]
    on_timer*: proc (plugin: ptr clap_plugin; timer_id: clap_id) {.cdecl.}

  clap_host_timer_support* {.bycopy.} = object
    ##  Registers a periodic timer.
    ##  The host may adjust the period if it is under a certain threshold.
    ##  30 Hz should be allowed.
    ##  Returns true on success.
    ##  [main-thread]
    register_timer*: proc (host: ptr clap_host; period_ms: uint32;
                         timer_id: ptr clap_id): bool {.cdecl.}
    ##  Returns true on success.
    ##  [main-thread]
    unregister_timer*: proc (host: ptr clap_host; timer_id: clap_id): bool {.cdecl.}

