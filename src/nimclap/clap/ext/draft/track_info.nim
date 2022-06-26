import
  ../../plugin, ../../color, ../../string-sizes

var CLAP_EXT_TRACK_INFO*: UncheckedArray[char] = "clap.track-info.draft/0"

type
  ClapTrackInfoT* {.bycopy.} = object
    id*: ClapId
    index*: int32T
    name*: array[clap_Name_Size, char]
    path*: array[clap_Path_Size, char] ##  Like "/group1/group2/drum-machine/drum-pad-13"
    channelCount*: int32T
    audioPortType*: cstring
    color*: ClapColorT
    isReturnTrack*: bool

  ClapPluginTrackInfoT* {.bycopy.} = object
    changed*: proc (plugin: ptr ClapPluginT) ##  [main-thread]

  ClapHostTrackInfoT* {.bycopy.} = object
    get*: proc (host: ptr ClapHostT; info: ptr ClapTrackInfoT): bool ##  Get info about the track the plugin belongs to.
                                                            ##  [main-thread]

