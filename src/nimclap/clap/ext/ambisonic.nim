import
  ../plugin

##  This extension can be used to specify the channel mapping used by the plugin.

let CLAP_EXT_AMBISONIC*: cstring = cstring"clap.ambisonic/3"

##  The latest draft is 100% compatible.
##  This compat ID may be removed in 2026.

let CLAP_EXT_AMBISONIC_COMPAT*: cstring = cstring"clap.ambisonic.draft/3"

let CLAP_PORT_AMBISONIC*: cstring = cstring"ambisonic"

type
  clap_ambisonic_ordering* = enum ##  FuMa channel ordering
    CLAP_AMBISONIC_ORDERING_FUMA = 0, ##  ACN channel ordering
    CLAP_AMBISONIC_ORDERING_ACN = 1


type
  clap_ambisonic_normalization* = enum
    CLAP_AMBISONIC_NORMALIZATION_MAXN = 0, CLAP_AMBISONIC_NORMALIZATION_SN3D = 1,
    CLAP_AMBISONIC_NORMALIZATION_N3D = 2, CLAP_AMBISONIC_NORMALIZATION_SN2D = 3,
    CLAP_AMBISONIC_NORMALIZATION_N2D = 4


type
  clap_ambisonic_config* {.bycopy.} = object
    ##  see clap_ambisonic_ordering
    ordering*: uint32
    ##  see clap_ambisonic_normalization
    normalization*: uint32

  clap_plugin_ambisonic* {.bycopy.} = object
    ##  Returns true if the given configuration is supported.
    ##  [main-thread]
    is_config_supported*: proc (plugin: ptr clap_plugin;
                              config: ptr clap_ambisonic_config): bool {.cdecl.}
    ##  Returns true on success
    ##  [main-thread]
    get_config*: proc (plugin: ptr clap_plugin; is_input: bool; port_index: uint32;
                     config: ptr clap_ambisonic_config): bool {.cdecl.}

  clap_host_ambisonic* {.bycopy.} = object
    ##  Informs the host that the info has changed.
    ##  The info can only change when the plugin is de-activated.
    ##  [main-thread]
    changed*: proc (host: ptr clap_host) {.cdecl.}

