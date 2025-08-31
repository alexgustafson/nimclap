import ../host
import ../plugin

let extLog*: cstring = cstring"clap.log"

const
  logDebug* = 0
  logInfo* = 1
  logWarning* = 2
  logError* = 3
  logFatal* = 4
    ##  These severities should be used to report misbehaviour.
    ##  The plugin one can be used by a layer between the plugin and the host.
  logHostMisbehaving* = 5
  logPluginMisbehaving* = 6

type
  LogSeverity* = int32
  HostLog* {.bycopy.} = object
    ##  Log a message through the host.
    ##  [thread-safe]
    log*: proc(host: ptr Host, severity: LogSeverity, msg: cstring) {.cdecl.}
