## !!!Ignored construct:  ﻿ # once [NewLine] # ../plugin.h [NewLine] # ../string-sizes.h [NewLine] / @page Audio Ports
## /
## / This extension provides a way for the plugin to describe its current audio ports.
## /
## / If the plugin does not implement this extension, it won't have audio ports.
## /
## / 32 bits support is required for both host and plugins. 64 bits audio is optional.
## /
## / The plugin is only allowed to change its ports configuration while it is deactivated. static const char CLAP_EXT_AUDIO_PORTS [ ] = clap.audio-ports ;
## Error: expected ';'!!!

var CLAP_PORT_MONO*: UncheckedArray[char] = "mono"

var CLAP_PORT_STEREO*: UncheckedArray[char] = "stereo"

const                         ##  This port is the main audio input or output.
     ##  There can be only one main input and main output.
     ##  Main port must be at index 0.
  CLAP_AUDIO_PORT_IS_MAIN* = 1 shl 0 ##  The port can be used with 64 bits audio
  CLAP_AUDIO_PORT_SUPPORTS_64BITS* = 1 shl 1 ##  64 bits audio is preferred with this port
  CLAP_AUDIO_PORT_PREFERS_64BITS* = 1 shl 2 ##  This port must be used with the same sample size as all the other ports which have this flags.
                                       ##  In other words if all ports have this flags then the plugin may either be used entirely with
                                       ##  64 bits audio or 32 bits audio, but it can't be mixed.
  CLAP_AUDIO_PORT_REQUIRES_COMMON_SAMPLE_SIZE* = 1 shl 3

type
  ClapAudioPortInfoT* {.bycopy.} = object
    id*: ClapId                ##  stable identifier
    name*: array[clap_Name_Size, char] ##  displayable name
    flags*: uint32T
    channelCount*: uint32T ##  If null or empty then it is unspecified (arbitrary audio).
                         ##  This filed can be compared against:
                         ##  - CLAP_PORT_MONO
                         ##  - CLAP_PORT_STEREO
                         ##  - CLAP_PORT_SURROUND (defined in the surround extension)
                         ##  - CLAP_PORT_AMBISONIC (defined in the ambisonic extension)
                         ##  - CLAP_PORT_CV (defined in the cv extension)
                         ##
                         ##  An extension can provide its own port type and way to inspect the channels.
    portType*: cstring ##  in-place processing: allow the host to use the same buffer for input and output
                     ##  if supported set the pair port id.
                     ##  if not supported set to CLAP_INVALID_ID
    inPlacePair*: ClapId


##  The audio ports scan has to be done while the plugin is deactivated.

type
  ClapPluginAudioPortsT* {.bycopy.} = object
    count*: proc (plugin: ptr ClapPluginT; isInput: bool): uint32T ##  number of ports, for either input or output
                                                           ##  [main-thread]
    ##  get info about about an audio port.
    ##  [main-thread]
    get*: proc (plugin: ptr ClapPluginT; index: uint32T; isInput: bool;
              info: ptr ClapAudioPortInfoT): bool


const                         ##  The ports name did change, the host can scan them right away.
  CLAP_AUDIO_PORTS_RESCAN_NAMES* = 1 shl 0 ##  [!active] The flags did change
  CLAP_AUDIO_PORTS_RESCAN_FLAGS* = 1 shl 1 ##  [!active] The channel_count did change
  CLAP_AUDIO_PORTS_RESCAN_CHANNEL_COUNT* = 1 shl 2 ##  [!active] The port type did change
  CLAP_AUDIO_PORTS_RESCAN_PORT_TYPE* = 1 shl 3 ##  [!active] The in-place pair did change, this requires.
  CLAP_AUDIO_PORTS_RESCAN_IN_PLACE_PAIR* = 1 shl 4 ##  [!active] The list of ports have changed: entries have been removed/added.
  CLAP_AUDIO_PORTS_RESCAN_LIST* = 1 shl 5

type
  ClapHostAudioPortsT* {.bycopy.} = object
    isRescanFlagSupported*: proc (host: ptr ClapHostT; flag: uint32T): bool ##  Checks if the host allows a plugin to change a given aspect of the audio ports definition.
                                                                    ##  [main-thread]
    ##  Rescan the full list of audio ports according to the flags.
    ##  It is illegal to ask the host to rescan with a flag that is not supported.
    ##  Certain flags require the plugin to be de-activated.
    ##  [main-thread]
    rescan*: proc (host: ptr ClapHostT; flags: uint32T)

