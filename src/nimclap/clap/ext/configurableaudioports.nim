import audioports, ../plugin

## This extension lets the host configure the plugin's input and output audio
## ports.
## This is a "push" approach to audio ports configuration.

let extConfigurableAudioPorts*: cstring =
  cstring"clap.configurable-audio-ports/1"

let extConfigurableAudioPortsCompat*: cstring =
  cstring"clap.configurable-audio-ports.draft1"
  ## The latest draft is 100% compatible.
  ## This compat ID may be removed in 2026.

type
  AudioPortConfigurationRequest* {.bycopy.} = object
    isInput*: bool
      ## Identifies the port by `isInput` and `portIndex`.
    portIndex*: uint32
    channelCount*: uint32
      ## The requested number of channels.
    portType*: cstring
      ## The port type, see the `audioports` module, `AudioPortInfo.portType`
      ## for interpretation.
    portDetails*: pointer
      ## Cast `portDetails` according to `portType`:
      ## - `portMono`: (discard)
      ## - `portStereo`: (discard)
      ## - `CLAP_PORT_SURROUND`: a `ptr uint8` channel map
      ## - `portAmbisonic`: a `ptr AmbisonicConfig` info

  PluginConfigurableAudioPorts* {.bycopy.} = object
    canApplyConfiguration*: proc(
      plugin: ptr Plugin,
      requests: ptr AudioPortConfigurationRequest,
      requestCount: uint32,
    ): bool {.cdecl.}
      ## Returns true if the given configurations can be applied using
      ## `applyConfiguration`.
      ## `[main-thread && !active]`
    applyConfiguration*: proc(
      plugin: ptr Plugin,
      requests: ptr AudioPortConfigurationRequest,
      requestCount: uint32,
    ): bool {.cdecl.}
      ## Submit a bunch of configuration requests which will atomically be
      ## applied together, or discarded together.
      ##
      ## Once the configuration is successfully applied, it isn't necessary for
      ## the plugin to call `HostAudioPorts.changed`; and it isn't necessary for
      ## the host to scan the audio ports.
      ##
      ## Returns true if applied.
      ## `[main-thread && !active]`
