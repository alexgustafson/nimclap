import
  ../plugin

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

let CLAP_EXT_SURROUND*: cstring = cstring"clap.surround/4"

##  The latest draft is 100% compatible.
##  This compat ID may be removed in 2026.

let CLAP_EXT_SURROUND_COMPAT*: cstring = cstring"clap.surround.draft/4"

let CLAP_PORT_SURROUND*: cstring = cstring"surround"

const
  CLAP_SURROUND_FL* = 0         ##  Front Left
  CLAP_SURROUND_FR* = 1         ##  Front Right
  CLAP_SURROUND_FC* = 2         ##  Front Center
  CLAP_SURROUND_LFE* = 3        ##  Low Frequency
  CLAP_SURROUND_BL* = 4         ##  Back Left
  CLAP_SURROUND_BR* = 5         ##  Back Right
  CLAP_SURROUND_FLC* = 6        ##  Front Left of Center
  CLAP_SURROUND_FRC* = 7        ##  Front Right of Center
  CLAP_SURROUND_BC* = 8         ##  Back Center
  CLAP_SURROUND_SL* = 9         ##  Side Left
  CLAP_SURROUND_SR* = 10        ##  Side Right
  CLAP_SURROUND_TC* = 11        ##  Top Center
  CLAP_SURROUND_TFL* = 12       ##  Front Left Height
  CLAP_SURROUND_TFC* = 13       ##  Front Center Height
  CLAP_SURROUND_TFR* = 14       ##  Front Right Height
  CLAP_SURROUND_TBL* = 15       ##  Rear Left Height
  CLAP_SURROUND_TBC* = 16       ##  Rear Center Height
  CLAP_SURROUND_TBR* = 17       ##  Rear Right Height

type
  clap_plugin_surround* {.bycopy.} = object
    ##  Checks if a given channel mask is supported.
    ##  The channel mask is a bitmask, for example:
    ##    (1 << CLAP_SURROUND_FL) | (1 << CLAP_SURROUND_FR) | ...
    ##  [main-thread]
    is_channel_mask_supported*: proc (plugin: ptr clap_plugin; channel_mask: uint64): bool {.
        cdecl.}
    ##  Stores the surround identifier of each channel into the channel_map array.
    ##  Returns the number of elements stored in channel_map.
    ##  channel_map_capacity must be greater or equal to the channel count of the given port.
    ##  [main-thread]
    get_channel_map*: proc (plugin: ptr clap_plugin; is_input: bool;
                          port_index: uint32; channel_map: ptr uint8;
                          channel_map_capacity: uint32): uint32 {.cdecl.}

  clap_host_surround* {.bycopy.} = object
    ##  Informs the host that the channel map has changed.
    ##  The channel map can only change when the plugin is de-activated.
    ##  [main-thread]
    changed*: proc (host: ptr clap_host) {.cdecl.}

