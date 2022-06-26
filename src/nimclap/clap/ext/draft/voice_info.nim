import
  ../../plugin

##  This extensions indicates the number of voices the synthesizer.
##  It is useful for the host when performing polyphonic modulations,
##  because the host needs its own voice management and should try to follow
##  what the plugin is doing:
##  - make the host's voice pool coherent with what the plugin has
##  - turn the host's voice management to mono when the plugin is mono

var CLAP_EXT_VOICE_INFO*: UncheckedArray[char] = "clap.voice-info.draft/0"

const ##  Allows the host to send overlapping NOTE_ON events.
     ##  The plugin will then rely upon the note_id to distinguish between them.
  CLAP_VOICE_INFO_SUPPORTS_OVERLAPPING_NOTES* = 1 shl 0

type
  ClapVoiceInfoT* {.bycopy.} = object
    voiceCount*: uint32T ##  voice_count is the current number of voices that the patch can use
                       ##  voice_capacity is the number of voices allocated voices
                       ##  voice_count should not be confused with the number of active voices.
                       ##
                       ##  1 <= voice_count <= voice_capacity
                       ##
                       ##  For example, a synth can have a capacity of 8 voices, but be configured
                       ##  to only use 4 voices: {count: 4, capacity: 8}.
                       ##
                       ##  If the voice_count is 1, then the synth is working in mono and the host
                       ##  can decide to only use global modulation mapping.
    voiceCapacity*: uint32T
    flags*: uint64T

  ClapPluginVoiceInfoT* {.bycopy.} = object
    get*: proc (plugin: ptr ClapPluginT; info: ptr ClapVoiceInfoT): bool ##  gets the voice info, returns true on success
                                                                ##  [main-thread && active]

  ClapHostVoiceInfoT* {.bycopy.} = object
    changed*: proc (host: ptr ClapHostT) ##  informs the host that the voice info have changed
                                    ##  [main-thread]

