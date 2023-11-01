import
  ../../plugin

##  This extension can be used to specify the cv channel type used by the plugin.
##  Work in progress, suggestions are welcome

let CLAP_EXT_CV*: cstring = cstring"clap.cv.draft/0"

let CLAP_PORT_CV*: cstring = cstring"cv"

const                         ##  TODO: standardize values?
  CLAP_CV_VALUE* = 0
  CLAP_CV_GATE* = 1
  CLAP_CV_PITCH* = 2

##  TODO: maybe we want a channel_info instead, where we could have more details about the supported
##  ranges?

type
  clap_plugin_cv* {.bycopy.} = object
    ##  Returns true on success.
    ##  [main-thread]
    get_channel_type*: proc (plugin: ptr clap_plugin; is_input: bool;
                           port_index: uint32; channel_index: uint32;
                           channel_type: ptr uint32): bool {.cdecl.}

  clap_host_cv* {.bycopy.} = object
    ##  Informs the host that the channels type have changed.
    ##  The channels type can only change when the plugin is de-activated.
    ##  [main-thread,!active]
    changed*: proc (host: ptr clap_host) {.cdecl.}

