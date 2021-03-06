import
  ../../plugin

##  This extension can be used to specify the channel mapping used by the plugin.
##
##  To have a consistent surround features across all the plugin instances,
##  here is the proposed workflow:
##  1. the plugin queries the host preferred channel mapping and
##     adjusts its configuration to match it.
##  2. the host checks how the plugin is effectively configured and honors it.
##
##  If the host decides to change the project's surround setup:
##  1. deactivate the plugin
##  2. host calls clap_plugin_surround->changed()
##  3. plugin calls clap_host_surround->get_preferred_channel_map()
##  4. plugin eventualy calls clap_host_surround->changed()
##  5. host calls clap_plugin_surround->get_channel_map() if changed
##  6. host activates the plugin and can start processing audio
##
##  If the plugin wants to change its surround setup:
##  1. call host->request_restart() if the plugin is active
##  2. once deactivated plugin calls clap_host_surround->changed()
##  3. host calls clap_plugin_surround->get_channel_map()
##  4. host activates the plugin and can start processing audio

var CLAP_EXT_SURROUND*: UncheckedArray[char] = "clap.surround.draft/1"

var CLAP_PORT_SURROUND*: UncheckedArray[char] = "surround"

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
  ClapPluginSurroundT* {.bycopy.} = object
    getChannelMap*: proc (plugin: ptr ClapPluginT; isInput: bool; portIndex: uint32T;
                        channelMap: ptr uint8T; channelMapCapacity: uint32T): uint32T ##  Stores into the channel_map array, the surround identifer of each channels.
                                                                                ##  Returns the number of elements stored in channel_map
                                                                                ##  [main-thread]
    ##  Informs the plugin that the host preferred channel map has changed.
    ##  [main-thread]
    changed*: proc (plugin: ptr ClapPluginT)

  ClapHostSurroundT* {.bycopy.} = object
    changed*: proc (host: ptr ClapHostT) ##  Informs the host that the channel map have changed.
                                    ##  The channel map can only change when the plugin is de-activated.
                                    ##  [main-thread]
    ##  Ask the host what is the prefered/project surround channel map.
    ##  [main-thread]
    getPreferredChannelMap*: proc (host: ptr ClapHostT; channelMap: ptr uint8T;
                                 channelMapCapacity: uint32T;
                                 channelCount: ptr uint32T)

