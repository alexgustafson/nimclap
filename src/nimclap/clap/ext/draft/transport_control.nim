import
  ../../plugin

##  This extension let the plugin submit transport requests to the host.
##  The host has no obligation to execute those request, so the interface maybe
##  partially working.

var CLAP_EXT_TRANSPORT_CONTROL*: UncheckedArray[char] = "clap.transport-control.draft/0"

type
  ClapHostTransportControlT* {.bycopy.} = object
    requestStart*: proc (host: ptr ClapHostT) ##  Jumps back to the start point and starts the transport
                                         ##  [main-thread]
    ##  Stops the transport, and jumps to the start point
    ##  [main-thread]
    requestStop*: proc (host: ptr ClapHostT) ##  If not playing, starts the transport from its current position
                                        ##  [main-thread]
    requestContinue*: proc (host: ptr ClapHostT) ##  If playing, stops the transport at the current position
                                            ##  [main-thread]
    requestPause*: proc (host: ptr ClapHostT) ##  Equivalent to what "space bar" does with most DAW
                                         ##  [main-thread]
    requestTogglePlay*: proc (host: ptr ClapHostT) ##  Jumps the transport to the given position.
                                              ##  Does not start the transport.
                                              ##  [main-thread]
    requestJump*: proc (host: ptr ClapHostT; position: ClapBeattime) ##  Sets the loop region
                                                              ##  [main-thread]
    requestLoopRegion*: proc (host: ptr ClapHostT; start: ClapBeattime;
                            duration: ClapBeattime) ##  Toggles looping
                                                  ##  [main-thread]
    requestToggleLoop*: proc (host: ptr ClapHostT) ##  Enables/Disables looping
                                              ##  [main-thread]
    requestEnableLoop*: proc (host: ptr ClapHostT; isEnabled: bool) ##  Enables/Disables recording
                                                             ##  [main-thread]
    requestRecord*: proc (host: ptr ClapHostT; isRecording: bool) ##  Toggles recording
                                                           ##  [main-thread]
    requestToggleRecord*: proc (host: ptr ClapHostT)

