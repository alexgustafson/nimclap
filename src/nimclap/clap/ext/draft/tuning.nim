import ../../plugin, ../../events, ../../stringsizes

let extTuning*: cstring = cstring"clap.tuning/2"

##  Use clap_host_event_registry->query(host, CLAP_EXT_TUNING, &space_id) to know the event space.
##
##  This event defines the tuning to be used on the given port/channel.

type
  EventTuning* {.bycopy.} = object
    header*: EventHeader
    portIndex*: int16
    ##  -1 global
    channel*: int16
    ##  0..15, -1 global
    tunningId*: Id

  TuningInfo* {.bycopy.} = object
    tuningId*: Id
    name*: array[name_Size, char]
    isDynamic*: bool ##  true if the values may vary with time

  PluginTuning* {.bycopy.} = object
    ##  Called when a tuning is added or removed from the pool.
    ##  [main-thread]
    changed*: proc(plugin: ptr Plugin) {.cdecl.}

##  This extension provides a dynamic tuning table to the plugin.

type HostTuning* {.bycopy.} = object
  ##  Gets the relative tuning in semitones against equal temperament with A4=440Hz.
  ##  The plugin may query the tuning at a rate that makes sense for *low* frequency modulations.
  ##
  ##  If the tuning_id is not found or equals to CLAP_INVALID_ID,
  ##  then the function shall gracefully return a sensible value.
  ##
  ##  sample_offset is the sample offset from the beginning of the current process block.
  ##
  ##  should_play(...) should be checked before calling this function.
  ##
  ##  [audio-thread & in-process]
  getRelative*: proc(
    host: ptr Host, tuningId: Id, channel: int32, key: int32, sampleOffset: uint32
  ): cdouble {.cdecl.}
  ##  Returns true if the note should be played.
  ##  [audio-thread & in-process]
  shouldPlay*:
    proc(host: ptr Host, tuningId: Id, channel: int32, key: int32): bool {.cdecl.}
  ##  Returns the number of tunings in the pool.
  ##  [main-thread]
  getTuningCount*: proc(host: ptr Host): uint32 {.cdecl.}
  ##  Gets info about a tuning
  ##  Returns true on success and stores the result into info.
  ##  [main-thread]
  getInfo*:
    proc(host: ptr Host, tuningIndex: uint32, info: ptr TuningInfo): bool {.cdecl.}
