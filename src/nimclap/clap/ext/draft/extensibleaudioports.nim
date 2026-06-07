import ../audioports, ../../plugin

## This extension lets the host add and remove audio ports to the plugin.

let extExtensibleAudioPorts*: cstring = cstring"clap.extensible-audio-ports/1"

type PluginExtensibleAudioPorts* {.bycopy.} = object
  addPort*: proc(
    plugin: ptr Plugin,
    isInput: bool,
    channelCount: uint32,
    portType: cstring,
    portDetails: pointer,
  ): bool {.cdecl.}
    ## Asks the plugin to add a new port (at the end of the list), with the
    ## following settings.
    ## `portType`: see `AudioPortInfo.portType` for interpretation.
    ## `portDetails`: see `AudioPortConfigurationRequest.portDetails` for
    ## interpretation.
    ## Returns true on success.
    ## `[main-thread && !is_active]`
  removePort*: proc(plugin: ptr Plugin, isInput: bool, index: uint32): bool {.cdecl.}
    ## Asks the plugin to remove a port.
    ## Returns true on success.
    ## `[main-thread && !is_active]`
