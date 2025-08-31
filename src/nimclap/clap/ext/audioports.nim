import ../id, ../host
import ../plugin, ../stringsizes

##  @page Audio Ports
##
##  This extension provides a way for the plugin to describe its current audio ports.
##
##  If the plugin does not implement this extension, it won't have audio ports.
##
##  32 bits support is required for both host and plugins. 64 bits audio is optional.
##
##  The plugin is only allowed to change its ports configuration while it is deactivated.

let extAudioPorts*: cstring = cstring"clap.audio-ports"

let portMono*: cstring = cstring"mono"

let portStereo*: cstring = cstring"stereo"

const
  ##  This port is the main audio input or output.
  ##  There can be only one main input and main output.
  ##  Main port must be at index 0.
  audioPortIsMain* = 1 shl 0 ##  This port can be used with 64 bits audio
  audioPortSupports64bits* = 1 shl 1 ##  64 bits audio is preferred with this port
  audioPortPrefers64bits* = 1 shl 2
    ##  This port must be used with the same sample size as all the other ports which have this flag.
    ##  In other words if all ports have this flag then the plugin may either be used entirely with
    ##  64 bits audio or 32 bits audio, but it can't be mixed.
  audioPortRequiresCommonSampleSize* = 1 shl 3

type AudioPortInfo* {.bycopy.} = object
  ##  id identifies a port and must be stable.
  ##  id may overlap between input and output ports.
  id*: Id
  name*: array[name_Size, char]
  ##  displayable name
  flags*: uint32
  channelCount*: uint32
  ##  If null or empty then it is unspecified (arbitrary audio).
  ##  This field can be compared against:
  ##  - CLAP_PORT_MONO
  ##  - CLAP_PORT_STEREO
  ##  - CLAP_PORT_SURROUND (defined in the surround extension)
  ##  - CLAP_PORT_AMBISONIC (defined in the ambisonic extension)
  ##
  ##  An extension can provide its own port type and way to inspect the channels.
  portType*: cstring
  ##  in-place processing: allow the host to use the same buffer for input and output
  ##  if supported set the pair port id.
  ##  if not supported set to CLAP_INVALID_ID
  inPlacePair*: Id

##  The audio ports scan has to be done while the plugin is deactivated.

type PluginAudioPorts* {.bycopy.} = object
  ##  Number of ports, for either input or output
  ##  [main-thread]
  count*: proc(plugin: ptr Plugin, isInput: bool): uint32 {.cdecl.}
  ##  Get info about an audio port.
  ##  Returns true on success and stores the result into info.
  ##  [main-thread]
  get*: proc(
    plugin: ptr Plugin, index: uint32, isInput: bool, info: ptr AudioPortInfo
  ): bool {.cdecl.}

const ##  The ports name did change, the host can scan them right away.
  audioPortsRescanNames* = 1 shl 0 ##  [!active] The flags did change
  audioPortsRescanFlags* = 1 shl 1 ##  [!active] The channel_count did change
  audioPortsRescanChannelCount* = 1 shl 2 ##  [!active] The port type did change
  audioPortsRescanPortType* = 1 shl 3
    ##  [!active] The in-place pair did change, this requires.
  audioPortsRescanInPlacePair* = 1 shl 4
    ##  [!active] The list of ports have changed: entries have been removed/added.
  audioPortsRescanList* = 1 shl 5

type HostAudioPorts* {.bycopy.} = object
  ##  Checks if the host allows a plugin to change a given aspect of the audio ports definition.
  ##  [main-thread]
  isRescanFlagSupported*: proc(host: ptr Host, flag: uint32): bool {.cdecl.}
  ##  Rescan the full list of audio ports according to the flags.
  ##  It is illegal to ask the host to rescan with a flag that is not supported.
  ##  Certain flags require the plugin to be de-activated.
  ##  [main-thread]
  rescan*: proc(host: ptr Host, flags: uint32) {.cdecl.}
