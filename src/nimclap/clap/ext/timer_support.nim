import
  ../plugin

var CLAP_EXT_TIMER_SUPPORT*: UncheckedArray[char] = "clap.timer-support"

type
  ClapPluginTimerSupportT* {.bycopy.} = object
    onTimer*: proc (plugin: ptr ClapPluginT; timerId: ClapId) ##  [main-thread]

  ClapHostTimerSupportT* {.bycopy.} = object
    registerTimer*: proc (host: ptr ClapHostT; periodMs: uint32T; timerId: ptr ClapId): bool ##  Registers a periodic timer.
                                                                                  ##  The host may adjust the period if it is under a certain threshold.
                                                                                  ##  30 Hz should be allowed.
                                                                                  ##  [main-thread]
    ##  [main-thread]
    unregisterTimer*: proc (host: ptr ClapHostT; timerId: ClapId): bool

