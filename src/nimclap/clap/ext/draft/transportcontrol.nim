import ../../plugin

##  This extension lets the plugin submit transport requests to the host.
##  The host has no obligation to execute these requests, so the interface may be
##  partially working.

let extTransportControl*: cstring = cstring"clap.transport-control/1"

type HostTransportControl* {.bycopy.} = object
  ##  Jumps back to the start point and starts the transport
  ##  [main-thread]
  requestStart*: proc(host: ptr Host) {.cdecl.}
  ##  Stops the transport, and jumps to the start point
  ##  [main-thread]
  requestStop*: proc(host: ptr Host) {.cdecl.}
  ##  If not playing, starts the transport from its current position
  ##  [main-thread]
  requestContinue*: proc(host: ptr Host) {.cdecl.}
  ##  If playing, stops the transport at the current position
  ##  [main-thread]
  requestPause*: proc(host: ptr Host) {.cdecl.}
  ##  Equivalent to what "space bar" does with most DAWs
  ##  [main-thread]
  requestTogglePlay*: proc(host: ptr Host) {.cdecl.}
  ##  Jumps the transport to the given position.
  ##  Does not start the transport.
  ##  [main-thread]
  requestJump*: proc(host: ptr Host, position: Beattime) {.cdecl.}
  ##  Sets the loop region
  ##  [main-thread]
  requestLoopRegion*:
    proc(host: ptr Host, start: Beattime, duration: Beattime) {.cdecl.}
  ##  Toggles looping
  ##  [main-thread]
  requestToggleLoop*: proc(host: ptr Host) {.cdecl.}
  ##  Enables/Disables looping
  ##  [main-thread]
  requestEnableLoop*: proc(host: ptr Host, isEnabled: bool) {.cdecl.}
  ##  Enables/Disables recording
  ##  [main-thread]
  requestRecord*: proc(host: ptr Host, isRecording: bool) {.cdecl.}
  ##  Toggles recording
  ##  [main-thread]
  requestToggleRecord*: proc(host: ptr Host) {.cdecl.}
