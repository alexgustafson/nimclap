import
  ../audioports

##  This extension lets the host configure the plugin's input and output audio ports.
##  This is a "push" approach to audio ports configuration.

let CLAP_EXT_CONFIGURABLE_AUDIO_PORTS*: UncheckedArray[char] = "clap.configurable-audio-ports.draft0"

type
  clap_audio_port_configuration_request* {.bycopy.} = object
    ##  When true, allows the plugin to pick a similar port configuration instead
    ##  if the requested one can't be applied.
    is_best_effort*: bool
    ##  Identifies the port by is_input and port_index
    is_input*: bool
    port_index*: uint32
    ##  The requested number of channels.
    channel_count*: uint32
    ##  The port type, see audio-ports.h, clap_audio_port_info.port_type for interpretation.
    port_type*: cstring
    ##  cast port_details according to port_type:
    ##  - CLAP_PORT_MONO: (discard)
    ##  - CLAP_PORT_STEREO: (discard)
    ##  - CLAP_PORT_SURROUND: const uint8_t *channel_map
    ##  - CLAP_PORT_AMBISONIC: const clap_ambisonic_info_t *info
    port_details*: pointer

  clap_plugin_configurable_audio_ports* {.bycopy.} = object
    ##  Some ports may not be configurable, or simply the result of another port configuration.
    ##  For example if you have a simple delay plugin, then the output port must have the exact
    ##  same type as the input port; in that example, we consider the output port type to be a
    ##  function (identity) of the input port type.
    ##  [main-thread && !active]
    is_port_configurable*: proc (plugin: ptr clap_plugin; is_input: bool;
                               port_index: uint32): bool {.cdecl.}
    ##  Submit a bunch of configuration requests which will atomically be applied together,
    ##  or discarded together.
    ##  [main-thread && !active]
    request_configuration*: proc (plugin: ptr clap_plugin; requests: ptr clap_audio_port_configuration_request;
                                request_count: uint32): bool {.cdecl.}

