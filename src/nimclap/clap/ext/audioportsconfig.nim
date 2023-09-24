import
  ../stringsizes, ../plugin, audioports

##  @page Audio Ports Config
##
##  This extension let the plugin provide port configurations presets.
##  For example mono, stereo, surround, ambisonic, ...
##
##  After the plugin initialization, the host may scan the list of configurations and eventually
##  select one that fits the plugin context. The host can only select a configuration if the plugin
##  is deactivated.
##
##  A configuration is a very simple description of the audio ports:
##  - it describes the main input and output ports
##  - it has a name that can be displayed to the user
##
##  The idea behind the configurations, is to let the user choose one via a menu.
##
##  Plugins with very complex configuration possibilities should let the user configure the ports
##  from the plugin GUI, and call @ref clap_host_audio_ports.rescan(CLAP_AUDIO_PORTS_RESCAN_ALL).
##
##  To inquire the exact bus layout, the plugin implements the clap_plugin_audio_ports_config_info_t
##  extension where all busses can be retrieved in the same way as in the audio-port extension.

let CLAP_EXT_AUDIO_PORTS_CONFIG*: UncheckedArray[char] = "clap.audio-ports-config"

let CLAP_EXT_AUDIO_PORTS_CONFIG_INFO*: UncheckedArray[char] = "clap.audio-ports-config-info/draft-0"

##  Minimalistic description of ports configuration

type
  clap_audio_ports_config* {.bycopy.} = object
    id*: clap_id
    name*: array[CLAP_NAME_SIZE, char]
    input_port_count*: uint32
    output_port_count*: uint32
    ##  main input info
    has_main_input*: bool
    main_input_channel_count*: uint32
    main_input_port_type*: cstring
    ##  main output info
    has_main_output*: bool
    main_output_channel_count*: uint32
    main_output_port_type*: cstring


##  The audio ports config scan has to be done while the plugin is deactivated.

type
  clap_plugin_audio_ports_config* {.bycopy.} = object
    ##  gets the number of available configurations
    ##  [main-thread]
    count*: proc (plugin: ptr clap_plugin): uint32 {.cdecl.}
    ##  gets information about a configuration
    ##  [main-thread]
    get*: proc (plugin: ptr clap_plugin; index: uint32;
              config: ptr clap_audio_ports_config): bool {.cdecl.}
    ##  selects the configuration designated by id
    ##  returns true if the configuration could be applied.
    ##  Once applied the host should scan again the audio ports.
    ##  [main-thread,plugin-deactivated]
    select*: proc (plugin: ptr clap_plugin; config_id: clap_id): bool {.cdecl.}


##  Extended config info

type
  clap_plugin_audio_ports_config_info* {.bycopy.} = object
    ##  Gets the id of the currently selected config, or CLAP_INVALID_ID if the current port
    ##  layout isn't part of the config list.
    ##
    ##  [main-thread]
    current_config*: proc (plugin: ptr clap_plugin): clap_id {.cdecl.}
    ##  Get info about an audio port, for a given config_id.
    ##  This is analogous to clap_plugin_audio_ports.get().
    ##  [main-thread]
    get*: proc (plugin: ptr clap_plugin; config_id: clap_id; port_index: uint32;
              is_input: bool; info: ptr clap_audio_port_info): bool {.cdecl.}

  clap_host_audio_ports_config* {.bycopy.} = object
    ##  Rescan the full list of configs.
    ##  [main-thread]
    rescan*: proc (host: ptr clap_host) {.cdecl.}

