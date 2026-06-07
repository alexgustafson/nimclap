import ../plugin, ../host

## This extension indicates the number of voices the synthesizer has.
## It is useful for the host when performing polyphonic modulations,
## because the host needs its own voice management and should try to follow
## what the plugin is doing:
## - make the host's voice pool coherent with what the plugin has
## - turn the host's voice management to mono when the plugin is mono

let extVoiceInfo*: cstring = cstring"clap.voice-info"

const
  voiceInfoSupportsOverlappingNotes* = 1 shl 0
    ## Allows the host to send overlapping `NOTE_ON` events.
    ## The plugin will then rely upon the `noteId` to distinguish between them.

type
  VoiceInfo* {.bycopy.} = object
    voiceCount*: uint32
      ## `voiceCount` is the current number of voices that the patch can use.
      ## `voiceCapacity` is the number of voices allocated voices.
      ## `voiceCount` should not be confused with the number of active voices.
      ##
      ## `1 <= voiceCount <= voiceCapacity`
      ##
      ## For example, a synth can have a capacity of 8 voices, but be configured
      ## to only use 4 voices: `{count: 4, capacity: 8}`.
      ##
      ## If the `voiceCount` is 1, then the synth is working in mono and the host
      ## can decide to only use global modulation mapping.
    voiceCapacity*: uint32
    flags*: uint64

  PluginVoiceInfo* {.bycopy.} = object
    get*: proc(plugin: ptr Plugin, info: ptr VoiceInfo): bool {.cdecl.}
      ## Gets the voice info, returns true on success.
      ## `[main-thread && active]`

  HostVoiceInfo* {.bycopy.} = object
    changed*: proc(host: ptr Host) {.cdecl.}
      ## Informs the host that the voice info has changed.
      ## `[main-thread]`
