import
  ../string-sizes, ../plugin

## / @page Audio Ports Config
## /
## / This extension provides a way for the plugin to describe possible ports configurations, for
## / example mono, stereo, surround, ... and a way for the host to select a configuration.
## /
## / After the plugin initialization, the host may scan the list of configurations and eventually
## / select one that fits the plugin context. The host can only select a configuration if the plugin
## / is deactivated.
## /
## / A configuration is a very simple description of the audio ports:
## / - it describes the main input and output ports
## / - it has a name that can be displayed to the user
## /
## / The idea behind the configurations, is to let the user choose one via a menu.
## /
## / Plugin with very complex configuration possibilities should let the user configure the ports
## / from the plugin GUI, and call @ref clap_host_audio_ports.rescan(CLAP_AUDIO_PORTS_RESCAN_ALL).

var CLAP_EXT_AUDIO_PORTS_CONFIG*: UncheckedArray[char] = "clap.audio-ports-config"

##  Minimalistic description of ports configuration

type
  ClapAudioPortsConfigT* {.bycopy.} = object
    id*: ClapId
    name*: array[clap_Name_Size, char]
    inputPortCount*: uint32T
    outputPortCount*: uint32T  ##  main input info
    hasMainInput*: bool
    mainInputChannelCount*: uint32T
    mainInputPortType*: cstring ##  main output info
    hasMainOutput*: bool
    mainOutputChannelCount*: uint32T
    mainOutputPortType*: cstring


##  The audio ports config scan has to be done while the plugin is deactivated.

type
  ClapPluginAudioPortsConfigT* {.bycopy.} = object
    count*: proc (plugin: ptr ClapPluginT): uint32T ##  gets the number of available configurations
                                              ##  [main-thread]
    ##  gets information about a configuration
    ##  [main-thread]
    get*: proc (plugin: ptr ClapPluginT; index: uint32T;
              config: ptr ClapAudioPortsConfigT): bool ##  selects the configuration designated by id
                                                   ##  returns true if the configuration could be applied
                                                   ##  [main-thread,plugin-deactivated]
    select*: proc (plugin: ptr ClapPluginT; configId: ClapId): bool

  ClapHostAudioPortsConfigT* {.bycopy.} = object
    rescan*: proc (host: ptr ClapHostT) ##  Rescan the full list of configs.
                                   ##  [main-thread]

