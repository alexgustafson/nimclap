import ../../color, ../../plugin, ../../stringsizes

##  This extension allows a host to tell the plugin more about its position
##  within a project or session.

let extProjectLocation*: cstring = cstring"clap.project-location/2"

type ProjectLocationKind* {.pure.} = enum ##  Represents a document/project/session.
  locationProject = 1
    ##  Represents a group of tracks.
    ##  It can contain track groups, tracks, and devices (post processing).
    ##  The first device within a track group has the index of
    ##  the last track or track group within this group + 1.
  locationTrackGroup = 2
    ##  Represents a single track.
    ##  It contains devices (serial).
  locationTrack = 3
    ##  Represents a single device.
    ##  It can contain other nested device chains.
  locationDevice = 4
    ##  Represents a nested device chain (serial).
    ##  Its parent must be a device.
    ##  It contains other devices.
  locationNestedDeviceChain = 5

type ProjectLocationTrackKind* {.pure.} = enum ##  This track is an instrument track.
  locationInstumentTrack = 1 ##  This track is an audio track.
  locationAudioTrack = 2 ##  This track is both an instrument and audio track.
  locationHybridTrack = 3 ##  This track is a return track.
  locationReturnTrack = 4
    ##  This track is a master track.
    ##  Each group have a master track for processing the sum of all its children tracks.
  locationMasterTrack = 5

type ProjectLocationFlags* {.pure.} = enum
  locationHasIndex = 1 shl 0
  locationHasColor = 1 shl 1

type
  ProjectLocationElement* {.bycopy.} = object
    ##  A bit-mask, see clap_project_location_flags.
    flags*: uint64
    ##  Kind of the element, must be one of the CLAP_PROJECT_LOCATION_* values.
    kind*: uint32
    ##  Only relevant if kind is CLAP_PLUGIN_LOCATION_TRACK.
    ##  see enum CLAP_PROJECT_LOCATION_track_kind.
    trackKind*: uint32
    ##  Index within the parent element.
    ##  Only usable if CLAP_PROJECT_LOCATION_HAS_INDEX is set in flags.
    index*: uint32
    ##  Internal ID of the element.
    ##  This is not intended for display to the user,
    ##  but rather to give the host a potential quick way for lookups.
    id*: array[path_Size, char]
    ##  User friendly name of the element.
    name*: array[name_Size, char]
    ##  Color for this element.
    ##  Only usable if CLAP_PROJECT_LOCATION_HAS_COLOR is set in flags.
    color*: Color

  PluginProjectLocation* {.bycopy.} = object
    ##  Called by the host when the location of the plugin instance changes.
    ##
    ##  The last item in this array always refers to the device itself, and as
    ##  such is expected to be of kind CLAP_PLUGIN_LOCATION_DEVICE.
    ##  The first item in this array always refers to the project this device is in and must be of
    ##  kind CLAP_PROJECT_LOCATION_PROJECT. The path is expected to be something like: PROJECT >
    ##  TRACK_GROUP+ > TRACK > (DEVICE > NESTED_DEVICE_CHAIN)* > DEVICE
    ##
    ##  [main-thread]
    set*: proc(
      plugin: ptr Plugin, path: ptr ProjectLocationElement, numElements: uint32
    ) {.cdecl.}
