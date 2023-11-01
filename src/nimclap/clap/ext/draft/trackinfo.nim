import
  ../../plugin, ../../color, ../../stringsizes

##  This extension let the plugin query info about the track it's in.
##  It is useful when the plugin is created, to initialize some parameters (mix, dry, wet)
##  and pick a suitable configuration regarding audio port type and channel count.

let CLAP_EXT_TRACK_INFO*: cstring = cstring"clap.track-info.draft/1"

const
  CLAP_TRACK_INFO_HAS_TRACK_NAME* = (1 shl 0)
  CLAP_TRACK_INFO_HAS_TRACK_COLOR* = (1 shl 1)
  CLAP_TRACK_INFO_HAS_AUDIO_CHANNEL* = (1 shl 2) ##  This plugin is on a return track, initialize with wet 100%
  CLAP_TRACK_INFO_IS_FOR_RETURN_TRACK* = (1 shl 3) ##  This plugin is on a bus track, initialize with appropriate settings for bus processing
  CLAP_TRACK_INFO_IS_FOR_BUS* = (1 shl 4) ##  This plugin is on the master, initialize with appropriate settings for channel processing
  CLAP_TRACK_INFO_IS_FOR_MASTER* = (1 shl 5)

type
  clap_track_info* {.bycopy.} = object
    flags*: uint64
    ##  see the flags above
    ##  track name, available if flags contain CLAP_TRACK_INFO_HAS_TRACK_NAME
    name*: array[CLAP_NAME_SIZE, char]
    ##  track color, available if flags contain CLAP_TRACK_INFO_HAS_TRACK_COLOR
    color*: clap_color
    ##  available if flags contain CLAP_TRACK_INFO_HAS_AUDIO_CHANNEL
    ##  see audio-ports.h, struct clap_audio_port_info to learn how to use channel count and port type
    audio_channel_count*: int32
    audio_port_type*: cstring

  clap_plugin_track_info* {.bycopy.} = object
    ##  Called when the info changes.
    ##  [main-thread]
    changed*: proc (plugin: ptr clap_plugin) {.cdecl.}

  clap_host_track_info* {.bycopy.} = object
    ##  Get info about the track the plugin belongs to.
    ##  [main-thread]
    get*: proc (host: ptr clap_host; info: ptr clap_track_info): bool {.cdecl.}

