import ../plugin

##  This extension can be used to specify the channel mapping used by the plugin.
##
##  To have consistent surround features across all the plugin instances,
##  here is the proposed workflow:
##  1. the plugin queries the host preferred channel mapping and
##     adjusts its configuration to match it.
##  2. the host checks how the plugin is effectively configured and honors it.
##
##  If the host decides to change the project's surround setup:
##  1. deactivate the plugin
##  2. host calls clap_plugin_surround->changed()
##  3. plugin calls clap_host_surround->get_preferred_channel_map()
##  4. plugin eventually calls clap_host_surround->changed()
##  5. host calls clap_plugin_surround->get_channel_map() if changed
##  6. host activates the plugin and can start processing audio
##
##  If the plugin wants to change its surround setup:
##  1. call host->request_restart() if the plugin is active
##  2. once deactivated plugin calls clap_host_surround->changed()
##  3. host calls clap_plugin_surround->get_channel_map()
##  4. host activates the plugin and can start processing audio

let extSurround*: cstring = cstring"clap.surround/4"

##  The latest draft is 100% compatible.
##  This compat ID may be removed in 2026.

let extSurroundCompat*: cstring = cstring"clap.surround.draft/4"

let portSurround*: cstring = cstring"surround"

const
  surroundFl* = 0 ##  Front Left
  surroundFr* = 1 ##  Front Right
  surroundFc* = 2 ##  Front Center
  surroundLfe* = 3 ##  Low Frequency
  surroundBl* = 4 ##  Back (Rear) Left
  surroundBr* = 5 ##  Back (Rear) Right
  surroundFlc* = 6 ##  Front Left of Center
  surroundFrc* = 7 ##  Front Right of Center
  surroundBc* = 8 ##  Back (Rear) Center
  surroundSl* = 9 ##  Side Left
  surroundSr* = 10 ##  Side Right
  surroundTc* = 11 ##  Top (Height) Center
  surroundTfl* = 12 ##  Top (Height) Front Left
  surroundTfc* = 13 ##  Top (Height) Front Center
  surroundTfr* = 14 ##  Top (Height) Front Right
  surroundTbl* = 15 ##  Top (Height) Back (Rear) Left
  surroundTbc* = 16 ##  Top (Height) Back (Rear) Center
  surroundTbr* = 17 ##  Top (Height) Back (Rear) Right
  surroundTsl* = 18 ##  Top (Height) Side Left
  surroundTsr* = 19 ##  Top (Height) Side Right

type
  PluginSurround* {.bycopy.} = object
    ##  Checks if a given channel mask is supported.
    ##  The channel mask is a bitmask, for example:
    ##    (1 << CLAP_SURROUND_FL) | (1 << CLAP_SURROUND_FR) | ...
    ##  [main-thread]
    isChannelMaskSupported*:
      proc(plugin: ptr Plugin, channelMask: uint64): bool {.cdecl.}
    ##  Stores the surround identifier of each channel into the channel_map array.
    ##  Returns the number of elements stored in channel_map.
    ##  channel_map_capacity must be greater or equal to the channel count of the given port.
    ##  [main-thread]
    getChannelMap*: proc(
      plugin: ptr Plugin,
      isInput: bool,
      portIndex: uint32,
      channelMap: ptr uint8,
      channelMapCapacity: uint32,
    ): uint32 {.cdecl.}

  HostSurround* {.bycopy.} = object
    ##  Informs the host that the channel map has changed.
    ##  The channel map can only change when the plugin is de-activated.
    ##  [main-thread]
    changed*: proc(host: ptr Host) {.cdecl.}
