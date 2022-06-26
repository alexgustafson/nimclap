import
  ../../plugin

##  This extension can be used to specify the channel mapping used by the plugin.

var CLAP_EXT_AMBISONIC*: UncheckedArray[char] = "clap.ambisonic.draft/0"

var CLAP_PORT_AMBISONIC*: UncheckedArray[char] = "ambisonic"

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
  ClapAmbisonicInfoT* {.bycopy.} = object
    ordering*: uint32T
    normalization*: uint32T

  ClapPluginAmbisonicT* {.bycopy.} = object
    getInfo*: proc (plugin: ptr ClapPluginT; isInput: bool; portIndex: uint32T;
                  info: ptr ClapAmbisonicInfoT): bool ##  Returns true on success
                                                  ##  [main-thread]

  ClapHostAmbisonicT* {.bycopy.} = object
    changed*: proc (host: ptr ClapHostT) ##  Informs the host that the info have changed.
                                    ##  The info can only change when the plugin is de-activated.
                                    ##  [main-thread]

