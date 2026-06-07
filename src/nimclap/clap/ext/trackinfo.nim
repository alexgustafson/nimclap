import ../plugin, ../color, ../stringsizes, ../host

## This extension let the plugin query info about the track it's in.
## It is useful when the plugin is created, to initialize some parameters (mix,
## dry, wet) and pick a suitable configuration regarding audio port type and
## channel count.

let extTrackInfo*: cstring = cstring"clap.track-info/1"

## The latest draft is 100% compatible.
## This compat ID may be removed in 2026.

let extTrackInfoCompat*: cstring = cstring"clap.track-info.draft/1"

const
  trackInfoHasTrackName* = (1 shl 0)
  trackInfoHasTrackColor* = (1 shl 1)
  trackInfoHasAudioChannel* = (1 shl 2)
  trackInfoIsForReturnTrack* = (1 shl 3)
    ## This plugin is on a return track, initialize with wet 100%.
  trackInfoIsForBus* = (1 shl 4)
    ## This plugin is on a bus track, initialize with appropriate settings for
    ## bus processing.
  trackInfoIsForMaster* = (1 shl 5)
    ## This plugin is on the master, initialize with appropriate settings for
    ## channel processing.

type
  TrackInfo* {.bycopy.} = object
    flags*: uint64
      ## See the flags above.
    name*: array[name_Size, char]
      ## Track name, available if flags contain `trackInfoHasTrackName`.
    color*: Color
      ## Track color, available if flags contain `trackInfoHasTrackColor`.
    audioChannelCount*: int32
      ## Available if flags contain `trackInfoHasAudioChannel`.
      ## See the `audio-ports` module, `AudioPortInfo`, to learn how to use
      ## channel count and port type.
    audioPortType*: cstring

  PluginTrackInfo* {.bycopy.} = object
    changed*: proc(plugin: ptr Plugin) {.cdecl.}
      ## Called when the info changes.
      ## `[main-thread]`

  HostTrackInfo* {.bycopy.} = object
    get*: proc(host: ptr Host, info: ptr TrackInfo): bool {.cdecl.}
      ## Get info about the track the plugin belongs to.
      ## Returns true on success and stores the result into `info`.
      ## `[main-thread]`
