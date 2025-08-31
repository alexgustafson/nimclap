import audioports

##  This extension lets the host configure the plugin's input and output audio ports.
##  This is a "push" approach to audio ports configuration.

let extConfigurableAudioPorts*: UncheckedArray[char] =
  "clap.configurable-audio-ports/1"

##  The latest draft is 100% compatible.
##  This compat ID may be removed in 2026.

let extConfigurableAudioPortsCompat*: UncheckedArray[char] =
  "clap.configurable-audio-ports.draft1"

type
  AudioPortConfigurationRequest* {.bycopy.} = object
    ##  Identifies the port by is_input and port_index
    isInput*: bool
    portIndex*: uint32
    ##  The requested number of channels.
    channelCount*: uint32
    ##  The port type, see audio-ports.h, clap_audio_port_info.port_type for interpretation.
    portType*: cstring
    ##  cast port_details according to port_type:
    ##  - CLAP_PORT_MONO: (discard)
    ##  - CLAP_PORT_STEREO: (discard)
    ##  - CLAP_PORT_SURROUND: const uint8_t *channel_map
    ##  - CLAP_PORT_AMBISONIC: const clap_ambisonic_config_t *info
    portDetails*: pointer

  PluginConfigurableAudioPorts* {.bycopy.} = object
    ##  Returns true if the given configurations can be applied using apply_configuration().
    ##  [main-thread && !active]
    canApplyConfiguration*: proc(
      plugin: ptr Plugin,
      requests: ptr AudioPortConfigurationRequest,
      requestCount: uint32,
    ): bool {.cdecl.}
    ##  Submit a bunch of configuration requests which will atomically be applied together,
    ##  or discarded together.
    ##
    ##  Once the configuration is successfully applied, it isn't necessary for the plugin to call
    ##  clap_host_audio_ports->changed(); and it isn't necessary for the host to scan the
    ##  audio ports.
    ##
    ##  Returns true if applied.
    ##  [main-thread && !active]
    applyConfiguration*: proc(
      plugin: ptr Plugin,
      requests: ptr AudioPortConfigurationRequest,
      requestCount: uint32,
    ): bool {.cdecl.}
