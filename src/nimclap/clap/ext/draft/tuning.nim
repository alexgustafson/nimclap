import
  ../../plugin, ../../events, ../../stringsizes

let CLAP_EXT_TUNING*: UncheckedArray[char] = "clap.tuning.draft/2"

##  Use clap_host_event_registry->query(host, CLAP_EXT_TUNING, &space_id) to know the event space.
##
##  This event defines the tuning to be used on the given port/channel.

type
  clap_event_tuning* {.bycopy.} = object
    header*: clap_event_header
    port_index*: int16
    ##  -1 global
    channel*: int16
    ##  0..15, -1 global
    tunning_id*: clap_id

  clap_tuning_info* {.bycopy.} = object
    tuning_id*: clap_id
    name*: array[CLAP_NAME_SIZE, char]
    is_dynamic*: bool
    ##  true if the values may vary with time

  clap_plugin_tuning* {.bycopy.} = object
    ##  Called when a tuning is added or removed from the pool.
    ##  [main-thread]
    changed*: proc (plugin: ptr clap_plugin) {.cdecl.}


##  This extension provides a dynamic tuning table to the plugin.

type
  clap_host_tuning* {.bycopy.} = object
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
    get_relative*: proc (host: ptr clap_host; tuning_id: clap_id; channel: int32;
                       key: int32; sample_offset: uint32): cdouble {.cdecl.}
    ##  Returns true if the note should be played.
    ##  [audio-thread & in-process]
    should_play*: proc (host: ptr clap_host; tuning_id: clap_id; channel: int32;
                      key: int32): bool {.cdecl.}
    ##  Returns the number of tunings in the pool.
    ##  [main-thread]
    get_tuning_count*: proc (host: ptr clap_host): uint32 {.cdecl.}
    ##  Gets info about a tuning
    ##  [main-thread]
    get_info*: proc (host: ptr clap_host; tuning_index: uint32;
                   info: ptr clap_tuning_info): bool {.cdecl.}

