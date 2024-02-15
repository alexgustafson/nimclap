import
  audioports

##  This extension lets the host configure the plugin's input and output audio ports.
##  This is a "push" approach to audio ports configuration.

let CLAP_EXT_CONFIGURABLE_AUDIO_PORTS*: cstring = cstring"clap.configurable-audio-ports/1"

##  The latest draft is 100% compatible.
##  This compat ID may be removed in 2026.

let CLAP_EXT_CONFIGURABLE_AUDIO_PORTS_COMPAT*: cstring = cstring"clap.configurable-audio-ports.draft1"

type
  clap_audio_port_configuration_request* {.bycopy.} = object
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
    ##  - CLAP_PORT_AMBISONIC: const clap_ambisonic_config_t *info
    port_details*: pointer

  clap_plugin_configurable_audio_ports* {.bycopy.} = object
    ##  Returns true if the given configurations can be applied using apply_configuration().
    ##  [main-thread && !active]
    can_apply_configuration*: proc (plugin: ptr clap_plugin; requests: ptr clap_audio_port_configuration_request;
                                  request_count: uint32): bool {.cdecl.}
    ##  Submit a bunch of configuration requests which will atomically be applied together,
    ##  or discarded together.
    ##
    ##  Once the configuration is successfully applied, it isn't necessary for the plugin to call
    ##  clap_host_audio_ports->changed(); and it isn't necessary for the host to scan the
    ##  audio ports.
    ##
    ##  Returns true if applied.
    ##  [main-thread && !active]
    apply_configuration*: proc (plugin: ptr clap_plugin; requests: ptr clap_audio_port_configuration_request;
                              request_count: uint32): bool {.cdecl.}

