import ../id, ../host
import ../plugin, ../stringsizes

## Audio Ports
##
## This extension provides a way for the plugin to describe its current audio
## ports.
##
## If the plugin does not implement this extension, it won't have audio ports.
##
## 32 bits support is required for both host and plugins. 64 bits audio is
## optional.
##
## The plugin is only allowed to change its ports configuration while it is
## deactivated.

let extAudioPorts*: cstring = cstring"clap.audio-ports"

let portMono*: cstring = cstring"mono"

let portStereo*: cstring = cstring"stereo"

const
  audioPortIsMain* = 1 shl 0
    ## This port is the main audio input or output.
    ## There can be only one main input and main output.
    ## Main port must be at index 0.
  audioPortSupports64bits* = 1 shl 1
    ## This port can be used with 64 bits audio.
  audioPortPrefers64bits* = 1 shl 2
    ## 64 bits audio is preferred with this port.
  audioPortRequiresCommonSampleSize* = 1 shl 3
    ## This port must be used with the same sample size as all the other ports
    ## which have this flag.
    ## In other words if all ports have this flag then the plugin may either be
    ## used entirely with 64 bits audio or 32 bits audio, but it can't be mixed.

type AudioPortInfo* {.bycopy.} = object
  id*: Id
    ## `id` identifies a port and must be stable.
    ## `id` may overlap between input and output ports.
  name*: array[name_Size, char]
    ## Displayable name.
  flags*: uint32
  channelCount*: uint32
  portType*: cstring
    ## If nil or empty then it is unspecified (arbitrary audio).
    ## This field can be compared against:
    ## - `portMono`
    ## - `portStereo`
    ## - `CLAP_PORT_SURROUND` (defined in the surround extension)
    ## - `portAmbisonic` (defined in the `ambisonic` module)
    ##
    ## An extension can provide its own port type and way to inspect the channels.
  inPlacePair*: Id
    ## In-place processing: allow the host to use the same buffer for input and
    ## output. If supported set the pair port id. If not supported set to
    ## `invalidId`.

type PluginAudioPorts* {.bycopy.} = object
  ## The audio ports scan has to be done while the plugin is deactivated.
  count*: proc(plugin: ptr Plugin, isInput: bool): uint32 {.cdecl.}
    ## Number of ports, for either input or output.
    ## `[main-thread]`
  get*: proc(
    plugin: ptr Plugin, index: uint32, isInput: bool, info: ptr AudioPortInfo
  ): bool {.cdecl.}
    ## Get info about an audio port.
    ## Returns true on success and stores the result into `info`.
    ## `[main-thread]`

const
  audioPortsRescanNames* = 1 shl 0
    ## The ports name did change, the host can scan them right away.
  audioPortsRescanFlags* = 1 shl 1
    ## `[!active]` The flags did change.
  audioPortsRescanChannelCount* = 1 shl 2
    ## `[!active]` The `channelCount` did change.
  audioPortsRescanPortType* = 1 shl 3
    ## `[!active]` The port type did change.
  audioPortsRescanInPlacePair* = 1 shl 4
    ## `[!active]` The in-place pair did change, this requires.
  audioPortsRescanList* = 1 shl 5
    ## `[!active]` The list of ports have changed: entries have been removed/added.

type HostAudioPorts* {.bycopy.} = object
  isRescanFlagSupported*: proc(host: ptr Host, flag: uint32): bool {.cdecl.}
    ## Checks if the host allows a plugin to change a given aspect of the audio
    ## ports definition.
    ## `[main-thread]`
  rescan*: proc(host: ptr Host, flags: uint32) {.cdecl.}
    ## Rescan the full list of audio ports according to the flags.
    ## It is illegal to ask the host to rescan with a flag that is not supported.
    ## Certain flags require the plugin to be de-activated.
    ## `[main-thread]`
