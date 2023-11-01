import
  ../../plugin

##  This extension can be used to specify the channel mapping used by the plugin.

let CLAP_EXT_AMBISONIC*: cstring = cstring"clap.ambisonic.draft/2"

let CLAP_PORT_AMBISONIC*: cstring = cstring"ambisonic"

const                         ##  FuMa channel ordering
  CLAP_AMBISONIC_FUMA* = 0      ##  ACN channel ordering
  CLAP_AMBISONIC_ACN* = 1

const
  CLAP_AMBISONIC_NORMALIZATION_MAXN* = 0
  CLAP_AMBISONIC_NORMALIZATION_SN3D* = 1
  CLAP_AMBISONIC_NORMALIZATION_N3D* = 2
  CLAP_AMBISONIC_NORMALIZATION_SN2D* = 3
  CLAP_AMBISONIC_NORMALIZATION_N2D* = 4

type
  clap_ambisonic_info* {.bycopy.} = object
    ordering*: uint32
    normalization*: uint32

  clap_plugin_ambisonic* {.bycopy.} = object
    ##  Returns true on success
    ##
    ##  config_id: the configuration id, see clap_plugin_audio_ports_config.
    ##  If config_id is CLAP_INVALID_ID, then this function queries the current port info.
    ##  [main-thread]
    get_info*: proc (plugin: ptr clap_plugin; is_input: bool; port_index: uint32;
                   info: ptr clap_ambisonic_info): bool {.cdecl.}

  clap_host_ambisonic* {.bycopy.} = object
    ##  Informs the host that the info has changed.
    ##  The info can only change when the plugin is de-activated.
    ##  [main-thread]
    changed*: proc (host: ptr clap_host) {.cdecl.}

