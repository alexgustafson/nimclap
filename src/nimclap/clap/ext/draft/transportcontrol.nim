import
  ../../plugin

##  This extension lets the plugin submit transport requests to the host.
##  The host has no obligation to execute these requests, so the interface may be
##  partially working.

let CLAP_EXT_TRANSPORT_CONTROL*: cstring = cstring"clap.transport-control.draft/0"

type
  clap_host_transport_control* {.bycopy.} = object
    ##  Jumps back to the start point and starts the transport
    ##  [main-thread]
    request_start*: proc (host: ptr clap_host) {.cdecl.}
    ##  Stops the transport, and jumps to the start point
    ##  [main-thread]
    request_stop*: proc (host: ptr clap_host) {.cdecl.}
    ##  If not playing, starts the transport from its current position
    ##  [main-thread]
    request_continue*: proc (host: ptr clap_host) {.cdecl.}
    ##  If playing, stops the transport at the current position
    ##  [main-thread]
    request_pause*: proc (host: ptr clap_host) {.cdecl.}
    ##  Equivalent to what "space bar" does with most DAWs
    ##  [main-thread]
    request_toggle_play*: proc (host: ptr clap_host) {.cdecl.}
    ##  Jumps the transport to the given position.
    ##  Does not start the transport.
    ##  [main-thread]
    request_jump*: proc (host: ptr clap_host; position: clap_beattime) {.cdecl.}
    ##  Sets the loop region
    ##  [main-thread]
    request_loop_region*: proc (host: ptr clap_host; start: clap_beattime;
                              duration: clap_beattime) {.cdecl.}
    ##  Toggles looping
    ##  [main-thread]
    request_toggle_loop*: proc (host: ptr clap_host) {.cdecl.}
    ##  Enables/Disables looping
    ##  [main-thread]
    request_enable_loop*: proc (host: ptr clap_host; is_enabled: bool) {.cdecl.}
    ##  Enables/Disables recording
    ##  [main-thread]
    request_record*: proc (host: ptr clap_host; is_recording: bool) {.cdecl.}
    ##  Toggles recording
    ##  [main-thread]
    request_toggle_record*: proc (host: ptr clap_host) {.cdecl.}

