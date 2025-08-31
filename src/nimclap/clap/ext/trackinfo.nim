import ../plugin, ../color, ../stringsizes

##  This extension let the plugin query info about the track it's in.
##  It is useful when the plugin is created, to initialize some parameters (mix, dry, wet)
##  and pick a suitable configuration regarding audio port type and channel count.

let extTrackInfo*: cstring = cstring"clap.track-info/1"

##  The latest draft is 100% compatible.
##  This compat ID may be removed in 2026.

let extTrackInfoCompat*: cstring = cstring"clap.track-info.draft/1"

const
  trackInfoHasTrackName* = (1 shl 0)
  trackInfoHasTrackColor* = (1 shl 1)
  trackInfoHasAudioChannel* = (1 shl 2)
    ##  This plugin is on a return track, initialize with wet 100%
  trackInfoIsForReturnTrack* = (1 shl 3)
    ##  This plugin is on a bus track, initialize with appropriate settings for bus processing
  trackInfoIsForBus* = (1 shl 4)
    ##  This plugin is on the master, initialize with appropriate settings for channel processing
  trackInfoIsForMaster* = (1 shl 5)

type
  TrackInfo* {.bycopy.} = object
    flags*: uint64
    ##  see the flags above
    ##  track name, available if flags contain CLAP_TRACK_INFO_HAS_TRACK_NAME
    name*: array[name_Size, char]
    ##  track color, available if flags contain CLAP_TRACK_INFO_HAS_TRACK_COLOR
    color*: Color
    ##  available if flags contain CLAP_TRACK_INFO_HAS_AUDIO_CHANNEL
    ##  see audio-ports.h, struct clap_audio_port_info to learn how to use channel count and port type
    audioChannelCount*: int32
    audioPortType*: cstring

  PluginTrackInfo* {.bycopy.} = object
    ##  Called when the info changes.
    ##  [main-thread]
    changed*: proc(plugin: ptr Plugin) {.cdecl.}

  HostTrackInfo* {.bycopy.} = object
    ##  Get info about the track the plugin belongs to.
    ##  Returns true on success and stores the result into info.
    ##  [main-thread]
    get*: proc(host: ptr Host, info: ptr TrackInfo): bool {.cdecl.}
