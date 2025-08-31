import ../plugin

##  This extension can be used to specify the channel mapping used by the plugin.

let extAmbisonic*: cstring = cstring"clap.ambisonic/3"

##  The latest draft is 100% compatible.
##  This compat ID may be removed in 2026.

let extAmbisonicCompat*: cstring = cstring"clap.ambisonic.draft/3"

let portAmbisonic*: cstring = cstring"ambisonic"

type AmbisonicOrdering* {.pure.} = enum ##  FuMa channel ordering
  orderingFuma = 0 ##  ACN channel ordering
  orderingAcn = 1

type AmbisonicNormalization* {.pure.} = enum
  normalizationMaxn = 0
  normalizationSn3d = 1
  normalizationN3d = 2
  normalizationSn2d = 3
  normalizationN2d = 4

type
  AmbisonicConfig* {.bycopy.} = object
    ordering*: uint32
    ##  see clap_ambisonic_ordering
    normalization*: uint32 ##  see clap_ambisonic_normalization

  PluginAmbisonic* {.bycopy.} = object
    ##  Returns true if the given configuration is supported.
    ##  [main-thread]
    isConfigSupported*:
      proc(plugin: ptr Plugin, config: ptr AmbisonicConfig): bool {.cdecl.}
    ##  Returns true on success
    ##  [main-thread]
    getConfig*: proc(
      plugin: ptr Plugin, isInput: bool, portIndex: uint32, config: ptr AmbisonicConfig
    ): bool {.cdecl.}

  HostAmbisonic* {.bycopy.} = object
    ##  Informs the host that the info has changed.
    ##  The info can only change when the plugin is de-activated.
    ##  [main-thread]
    changed*: proc(host: ptr Host) {.cdecl.}
