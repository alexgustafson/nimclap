import ../audioports

##  This extension lets the host add and remove audio ports to the plugin.

let extExtensibleAudioPorts*: cstring = cstring"clap.extensible-audio-ports/1"

type PluginExtensibleAudioPorts* {.bycopy.} = object
  ##  Asks the plugin to add a new port (at the end of the list), with the following settings.
  ##  port_type: see clap_audio_port_info.port_type for interpretation.
  ##  port_details: see clap_audio_port_configuration_request.port_details for interpretation.
  ##  Returns true on success.
  ##  [main-thread && !is_active]
  addPort*: proc(
    plugin: ptr Plugin,
    isInput: bool,
    channelCount: uint32,
    portType: cstring,
    portDetails: pointer,
  ): bool {.cdecl.}
  ##  Asks the plugin to remove a port.
  ##  Returns true on success.
  ##  [main-thread && !is_active]
  removePort*: proc(plugin: ptr Plugin, isInput: bool, index: uint32): bool {.cdecl.}
