import ../stringsizes, ../plugin, audioports, ../host, ../id

## Audio Ports Config
##
## This extension let the plugin provide port configurations presets.
## For example mono, stereo, surround, ambisonic, ...
##
## After the plugin initialization, the host may scan the list of configurations
## and eventually select one that fits the plugin context. The host can only
## select a configuration if the plugin is deactivated.
##
## A configuration is a very simple description of the audio ports:
## - it describes the main input and output ports
## - it has a name that can be displayed to the user
##
## The idea behind the configurations, is to let the user choose one via a menu.
##
## Plugins with very complex configuration possibilities should let the user
## configure the ports from the plugin GUI, and call
## `HostAudioPorts.rescan(CLAP_AUDIO_PORTS_RESCAN_ALL)`.
##
## To inquire the exact bus layout, the plugin implements the
## `PluginAudioPortsConfigInfo` extension where all busses can be retrieved in
## the same way as in the audio-port extension.

let extAudioPortsConfig*: cstring = cstring"clap.audio-ports-config"

let extAudioPortsConfigInfo*: cstring =
  cstring"clap.audio-ports-config-info/1"

let extAudioPortsConfigInfoCompat*: cstring =
  cstring"clap.audio-ports-config-info/draft-0"
  ## The latest draft is 100% compatible.
  ## This compat ID may be removed in 2026.

type AudioPortsConfig* {.bycopy.} = object
  ## Minimalistic description of ports configuration.
  id*: Id
  name*: array[name_Size, char]
  inputPortCount*: uint32
  outputPortCount*: uint32
  hasMainInput*: bool
    ## Main input info.
  mainInputChannelCount*: uint32
  mainInputPortType*: cstring
  hasMainOutput*: bool
    ## Main output info.
  mainOutputChannelCount*: uint32
  mainOutputPortType*: cstring

type PluginAudioPortsConfig* {.bycopy.} = object
  ## The audio ports config scan has to be done while the plugin is deactivated.
  count*: proc(plugin: ptr Plugin): uint32 {.cdecl.}
    ## Gets the number of available configurations.
    ## `[main-thread]`
  get*: proc(plugin: ptr Plugin, index: uint32, config: ptr AudioPortsConfig): bool {.
    cdecl
  .}
    ## Gets information about a configuration.
    ## Returns true on success and stores the result into `config`.
    ## `[main-thread]`
  select*: proc(plugin: ptr Plugin, configId: Id): bool {.cdecl.}
    ## Selects the configuration designated by id.
    ## Returns true if the configuration could be applied.
    ## Once applied the host should scan again the audio ports.
    ## `[main-thread & plugin-deactivated]`

type
  PluginAudioPortsConfigInfo* {.bycopy.} = object
    ## Extended config info.
    currentConfig*: proc(plugin: ptr Plugin): Id {.cdecl.}
      ## Gets the id of the currently selected config, or `invalidId` if the
      ## current port layout isn't part of the config list.
      ##
      ## `[main-thread]`
    get*: proc(
      plugin: ptr Plugin,
      configId: Id,
      portIndex: uint32,
      isInput: bool,
      info: ptr AudioPortInfo,
    ): bool {.cdecl.}
      ## Get info about an audio port, for a given `configId`.
      ## This is analogous to `PluginAudioPorts.get`.
      ## Returns true on success and stores the result into `info`.
      ## `[main-thread]`

  HostAudioPortsConfig* {.bycopy.} = object
    rescan*: proc(host: ptr Host) {.cdecl.}
      ## Rescan the full list of configs.
      ## `[main-thread]`
