import ../../color, ../../plugin, ../../stringsizes

## This extension allows a host to tell the plugin more about its position
## within a project or session.

let extProjectLocation*: cstring = cstring"clap.project-location/2"

type ProjectLocationKind* {.pure.} = enum
  locationProject = 1
    ## Represents a document/project/session.
  locationTrackGroup = 2
    ## Represents a group of tracks.
    ## It can contain track groups, tracks, and devices (post processing).
    ## The first device within a track group has the index of
    ## the last track or track group within this group + 1.
  locationTrack = 3
    ## Represents a single track.
    ## It contains devices (serial).
  locationDevice = 4
    ## Represents a single device.
    ## It can contain other nested device chains.
  locationNestedDeviceChain = 5
    ## Represents a nested device chain (serial).
    ## Its parent must be a device.
    ## It contains other devices.

type ProjectLocationTrackKind* {.pure.} = enum
  locationInstumentTrack = 1
    ## This track is an instrument track.
  locationAudioTrack = 2
    ## This track is an audio track.
  locationHybridTrack = 3
    ## This track is both an instrument and audio track.
  locationReturnTrack = 4
    ## This track is a return track.
  locationMasterTrack = 5
    ## This track is a master track.
    ## Each group have a master track for processing the sum of all its children tracks.

type ProjectLocationFlags* {.pure.} = enum
  locationHasIndex = 1 shl 0
  locationHasColor = 1 shl 1

type
  ProjectLocationElement* {.bycopy.} = object
    flags*: uint64
      ## A bit-mask, see `ProjectLocationFlags`.
    kind*: uint32
      ## Kind of the element, must be one of the `ProjectLocationKind` values.
    trackKind*: uint32
      ## Only relevant if kind is `locationTrack`.
      ## see enum `ProjectLocationTrackKind`.
    index*: uint32
      ## Index within the parent element.
      ## Only usable if `locationHasIndex` is set in flags.
    id*: array[path_Size, char]
      ## Internal ID of the element.
      ## This is not intended for display to the user,
      ## but rather to give the host a potential quick way for lookups.
    name*: array[name_Size, char]
      ## User friendly name of the element.
    color*: Color
      ## Color for this element.
      ## Only usable if `locationHasColor` is set in flags.

  PluginProjectLocation* {.bycopy.} = object
    set*: proc(
      plugin: ptr Plugin, path: ptr ProjectLocationElement, numElements: uint32
    ) {.cdecl.}
      ## Called by the host when the location of the plugin instance changes.
      ##
      ## The last item in this array always refers to the device itself, and as
      ## such is expected to be of kind `locationDevice`.
      ## The first item in this array always refers to the project this device is in and must be of
      ## kind `locationProject`. The path is expected to be something like: PROJECT >
      ## TRACK_GROUP+ > TRACK > (DEVICE > NESTED_DEVICE_CHAIN)* > DEVICE
      ##
      ## `[main-thread]`
