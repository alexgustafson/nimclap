import
  ../../color, ../../plugin, ../../stringsizes

##  This extension allows a host to tell the plugin more about its position
##  within a project or session.

let CLAP_EXT_PROJECT_LOCATION*: cstring = cstring"clap.project-location/2"

type
  clap_project_location_kind* = enum ##  Represents a document/project/session.
    CLAP_PROJECT_LOCATION_PROJECT = 1, ##  Represents a group of tracks.
                                    ##  It can contain track groups, tracks, and devices (post processing).
                                    ##  The first device within a track group has the index of
                                    ##  the last track or track group within this group + 1.
    CLAP_PROJECT_LOCATION_TRACK_GROUP = 2, ##  Represents a single track.
                                        ##  It contains devices (serial).
    CLAP_PROJECT_LOCATION_TRACK = 3, ##  Represents a single device.
                                  ##  It can contain other nested device chains.
    CLAP_PROJECT_LOCATION_DEVICE = 4, ##  Represents a nested device chain (serial).
                                   ##  Its parent must be a device.
                                   ##  It contains other devices.
    CLAP_PROJECT_LOCATION_NESTED_DEVICE_CHAIN = 5


type
  clap_project_location_track_kind* = enum ##  This track is an instrument track.
    CLAP_PROJECT_LOCATION_INSTUMENT_TRACK = 1, ##  This track is an audio track.
    CLAP_PROJECT_LOCATION_AUDIO_TRACK = 2, ##  This track is both an instrument and audio track.
    CLAP_PROJECT_LOCATION_HYBRID_TRACK = 3, ##  This track is a return track.
    CLAP_PROJECT_LOCATION_RETURN_TRACK = 4, ##  This track is a master track.
                                         ##  Each group have a master track for processing the sum of all its children tracks.
    CLAP_PROJECT_LOCATION_MASTER_TRACK = 5


type
  clap_project_location_flags* = enum
    CLAP_PROJECT_LOCATION_HAS_INDEX = 1 shl 0,
    CLAP_PROJECT_LOCATION_HAS_COLOR = 1 shl 1


type
  clap_project_location_element* {.bycopy.} = object
    ##  A bit-mask, see clap_project_location_flags.
    flags*: uint64
    ##  Kind of the element, must be one of the CLAP_PROJECT_LOCATION_* values.
    kind*: uint32
    ##  Only relevant if kind is CLAP_PLUGIN_LOCATION_TRACK.
    ##  see enum CLAP_PROJECT_LOCATION_track_kind.
    track_kind*: uint32
    ##  Index within the parent element.
    ##  Only usable if CLAP_PROJECT_LOCATION_HAS_INDEX is set in flags.
    index*: uint32
    ##  Internal ID of the element.
    ##  This is not intended for display to the user,
    ##  but rather to give the host a potential quick way for lookups.
    id*: array[CLAP_PATH_SIZE, char]
    ##  User friendly name of the element.
    name*: array[CLAP_NAME_SIZE, char]
    ##  Color for this element.
    ##  Only usable if CLAP_PROJECT_LOCATION_HAS_COLOR is set in flags.
    color*: clap_color

  clap_plugin_project_location* {.bycopy.} = object
    ##  Called by the host when the location of the plugin instance changes.
    ##
    ##  The last item in this array always refers to the device itself, and as
    ##  such is expected to be of kind CLAP_PLUGIN_LOCATION_DEVICE.
    ##  The first item in this array always refers to the project this device is in and must be of
    ##  kind CLAP_PROJECT_LOCATION_PROJECT. The path is expected to be something like: PROJECT >
    ##  TRACK_GROUP+ > TRACK > (DEVICE > NESTED_DEVICE_CHAIN)* > DEVICE
    ##
    ##  [main-thread]
    set*: proc (plugin: ptr clap_plugin; path: ptr clap_project_location_element;
              num_elements: uint32) {.cdecl.}

