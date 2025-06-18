import ../id, ../host
import
  ../plugin, ../stringsizes

##  @page Audio Ports
##
##  This extension provides a way for the plugin to describe its current audio ports.
##
##  If the plugin does not implement this extension, it won't have audio ports.
##
##  32 bits support is required for both host and plugins. 64 bits audio is optional.
##
##  The plugin is only allowed to change its ports configuration while it is deactivated.

let CLAP_EXT_AUDIO_PORTS*: cstring = cstring"clap.audio-ports"

let CLAP_PORT_MONO*: cstring = cstring"mono"

let CLAP_PORT_STEREO*: cstring = cstring"stereo"

const                         ##  This port is the main audio input or output.
     ##  There can be only one main input and main output.
     ##  Main port must be at index 0.
  CLAP_AUDIO_PORT_IS_MAIN* = 1 shl 0 ##  This port can be used with 64 bits audio
  CLAP_AUDIO_PORT_SUPPORTS_64BITS* = 1 shl 1 ##  64 bits audio is preferred with this port
  CLAP_AUDIO_PORT_PREFERS_64BITS* = 1 shl 2 ##  This port must be used with the same sample size as all the other ports which have this flag.
                                       ##  In other words if all ports have this flag then the plugin may either be used entirely with
                                       ##  64 bits audio or 32 bits audio, but it can't be mixed.
  CLAP_AUDIO_PORT_REQUIRES_COMMON_SAMPLE_SIZE* = 1 shl 3

type
  clap_audio_port_info* {.bycopy.} = object
    ##  id identifies a port and must be stable.
    ##  id may overlap between input and output ports.
    id*: clap_id
    ##  displayable name
    name*: array[CLAP_NAME_SIZE, char]
    flags*: uint32
    channel_count*: uint32
    ##  If null or empty then it is unspecified (arbitrary audio).
    ##  This field can be compared against:
    ##  - CLAP_PORT_MONO
    ##  - CLAP_PORT_STEREO
    ##  - CLAP_PORT_SURROUND (defined in the surround extension)
    ##  - CLAP_PORT_AMBISONIC (defined in the ambisonic extension)
    ##
    ##  An extension can provide its own port type and way to inspect the channels.
    port_type*: cstring
    ##  in-place processing: allow the host to use the same buffer for input and output
    ##  if supported set the pair port id.
    ##  if not supported set to CLAP_INVALID_ID
    in_place_pair*: clap_id


##  The audio ports scan has to be done while the plugin is deactivated.

type
  clap_plugin_audio_ports* {.bycopy.} = object
    ##  Number of ports, for either input or output
    ##  [main-thread]
    count*: proc (plugin: ptr clap_plugin; is_input: bool): uint32 {.cdecl.}
    ##  Get info about an audio port.
    ##  Returns true on success and stores the result into info.
    ##  [main-thread]
    get*: proc (plugin: ptr clap_plugin; index: uint32; is_input: bool;
              info: ptr clap_audio_port_info): bool {.cdecl.}


const                         ##  The ports name did change, the host can scan them right away.
  CLAP_AUDIO_PORTS_RESCAN_NAMES* = 1 shl 0 ##  [!active] The flags did change
  CLAP_AUDIO_PORTS_RESCAN_FLAGS* = 1 shl 1 ##  [!active] The channel_count did change
  CLAP_AUDIO_PORTS_RESCAN_CHANNEL_COUNT* = 1 shl 2 ##  [!active] The port type did change
  CLAP_AUDIO_PORTS_RESCAN_PORT_TYPE* = 1 shl 3 ##  [!active] The in-place pair did change, this requires.
  CLAP_AUDIO_PORTS_RESCAN_IN_PLACE_PAIR* = 1 shl 4 ##  [!active] The list of ports have changed: entries have been removed/added.
  CLAP_AUDIO_PORTS_RESCAN_LIST* = 1 shl 5

type
  clap_host_audio_ports* {.bycopy.} = object
    ##  Checks if the host allows a plugin to change a given aspect of the audio ports definition.
    ##  [main-thread]
    is_rescan_flag_supported*: proc (host: ptr clap_host; flag: uint32): bool {.cdecl.}
    ##  Rescan the full list of audio ports according to the flags.
    ##  It is illegal to ask the host to rescan with a flag that is not supported.
    ##  Certain flags require the plugin to be de-activated.
    ##  [main-thread]
    rescan*: proc (host: ptr clap_host; flags: uint32) {.cdecl.}

