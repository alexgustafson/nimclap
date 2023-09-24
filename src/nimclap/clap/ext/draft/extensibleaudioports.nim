import
  ../audioports

##  This extension lets the host add and remove audio ports to the plugin.

let CLAP_EXT_EXTENSIBLE_AUDIO_PORTS*: UncheckedArray[char] = "clap.extensible-audio-ports.draft0"

type
  clap_plugin_extensible_audio_ports* {.bycopy.} = object
    ##  Asks the plugin to add a new port (at the end of the list), with the following settings.
    ##  port_type: see clap_audio_port_info.port_type for interpretation.
    ##  port_details: see clap_audio_port_configuration_request.port_details for interpretation.
    ##  Returns true on success.
    ##  [main-thread && !is_active]
    add_port*: proc (plugin: ptr clap_plugin; is_input: bool; channel_count: uint32;
                   port_type: cstring; port_details: pointer): bool {.cdecl.}
    ##  Asks the plugin to remove a port.
    ##  Returns true on success.
    ##  [main-thread && !is_active]
    remove_port*: proc (plugin: ptr clap_plugin; is_input: bool; index: uint32): bool {.
        cdecl.}

