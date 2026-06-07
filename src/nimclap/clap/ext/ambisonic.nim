import ../plugin, ../host

let extAmbisonic*: cstring = cstring"clap.ambisonic/3"
  ## This extension can be used to specify the channel mapping used by the plugin.

let extAmbisonicCompat*: cstring = cstring"clap.ambisonic.draft/3"
  ## The latest draft is 100% compatible.
  ## This compat ID may be removed in 2026.

let portAmbisonic*: cstring = cstring"ambisonic"

type AmbisonicOrdering* {.pure.} = enum
  orderingFuma = 0
    ## FuMa channel ordering.
  orderingAcn = 1
    ## ACN channel ordering.

type AmbisonicNormalization* {.pure.} = enum
  normalizationMaxn = 0
  normalizationSn3d = 1
  normalizationN3d = 2
  normalizationSn2d = 3
  normalizationN2d = 4

type
  AmbisonicConfig* {.bycopy.} = object
    ordering*: uint32
      ## See `AmbisonicOrdering`.
    normalization*: uint32
      ## See `AmbisonicNormalization`.

  PluginAmbisonic* {.bycopy.} = object
    isConfigSupported*:
      proc(plugin: ptr Plugin, config: ptr AmbisonicConfig): bool {.cdecl.}
      ## Returns true if the given configuration is supported.
      ## `[main-thread]`
    getConfig*: proc(
      plugin: ptr Plugin, isInput: bool, portIndex: uint32, config: ptr AmbisonicConfig
    ): bool {.cdecl.}
      ## Returns true on success.
      ## `[main-thread]`

  HostAmbisonic* {.bycopy.} = object
    changed*: proc(host: ptr Host) {.cdecl.}
      ## Informs the host that the info has changed.
      ## The info can only change when the plugin is de-activated.
      ## `[main-thread]`
