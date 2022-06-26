import
  ../plugin

var CLAP_EXT_LOG*: UncheckedArray[char] = "clap.log"

const
  CLAP_LOG_DEBUG* = 0
  CLAP_LOG_INFO* = 1
  CLAP_LOG_WARNING* = 2
  CLAP_LOG_ERROR* = 3
  CLAP_LOG_FATAL* = 4 ##  Those severities should be used to report misbehaviour.
                   ##  The plugin one can be used by a layer between the plugin and the host.
  CLAP_LOG_HOST_MISBEHAVING* = 5
  CLAP_LOG_PLUGIN_MISBEHAVING* = 6

type
  ClapLogSeverity* = int32T
  ClapHostLogT* {.bycopy.} = object
    log*: proc (host: ptr ClapHostT; severity: ClapLogSeverity; msg: cstring) ##  Log a message through the host.
                                                                     ##  [thread-safe]

