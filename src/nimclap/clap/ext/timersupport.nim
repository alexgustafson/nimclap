import ../plugin, ../host, ../id

let extTimerSupport*: cstring = cstring"clap.timer-support"

type
  PluginTimerSupport* {.bycopy.} = object
    onTimer*: proc(plugin: ptr Plugin, timerId: Id) {.cdecl.}
      ## `[main-thread]`

  HostTimerSupport* {.bycopy.} = object
    registerTimer*:
      proc(host: ptr Host, periodMs: uint32, timerId: ptr Id): bool {.cdecl.}
      ## Registers a periodic timer.
      ## The host may adjust the period if it is under a certain threshold.
      ## 30 Hz should be allowed.
      ## Returns true on success.
      ## `[main-thread]`
    unregisterTimer*: proc(host: ptr Host, timerId: Id): bool {.cdecl.}
      ## Returns true on success.
      ## `[main-thread]`
