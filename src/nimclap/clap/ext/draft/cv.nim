import
  ../../plugin

##  This extension can be used to specify the cv channel type used by the plugin.
##  Work in progress, suggestions are welcome

var CLAP_EXT_CV*: UncheckedArray[char] = "clap.cv.draft/0"

var CLAP_PORT_CV*: UncheckedArray[char] = "cv"

const                         ##  TODO: standardize values?
  CLAP_CV_VALUE* = 0
  CLAP_CV_GATE* = 1
  CLAP_CV_PITCH* = 2

##  TODO: maybe we want a channel_info instead, where we could have more details about the supported
##  ranges?

type
  ClapPluginCvT* {.bycopy.} = object
    getChannelType*: proc (plugin: ptr ClapPluginT; isInput: bool; portIndex: uint32T;
                         channelIndex: uint32T; channelType: ptr uint32T): bool ##  Returns true on success.
                                                                          ##  [main-thread]

  ClapHostCvT* {.bycopy.} = object
    changed*: proc (host: ptr ClapHostT) ##  Informs the host that the channels type have changed.
                                    ##  The channels type can only change when the plugin is de-activated.
                                    ##  [main-thread,!active]

