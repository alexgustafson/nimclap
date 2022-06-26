import
  ../../plugin, ../../events, ../../string-sizes

var CLAP_EXT_TUNING*: UncheckedArray[char] = "clap.tuning.draft/2"

##  Use clap_host_event_registry->query(host, CLAP_EXT_TUNING, &space_id) to know the event space.
##
##  This event defines the tuning to be used on the given port/channel.

type
  ClapEventTuningT* {.bycopy.} = object
    header*: ClapEventHeaderT
    portIndex*: int16T         ##  -1 global
    channel*: int16T           ##  0..15, -1 global
    tunningId*: ClapId

  ClapTuningInfoT* {.bycopy.} = object
    tuningId*: ClapId
    name*: array[clap_Name_Size, char]
    isDynamic*: bool           ##  true if the values may vary with time

  ClapPluginTuningT* {.bycopy.} = object
    changed*: proc (plugin: ptr ClapPluginT) ##  Called when a tuning is added or removed from the pool.
                                        ##  [main-thread]


##  This extension provides a dynamic tuning table to the plugin.

type
  ClapHostTuningT* {.bycopy.} = object
    getRelative*: proc (host: ptr ClapHostT; tuningId: ClapId; channel: int32T;
                      key: int32T; sampleOffset: uint32T): cdouble ##  Gets the relative tuning in semitone against equal temperament with A4=440Hz.
                                                              ##  The plugin may query the tuning at a rate that makes sense for *low* frequency modulations.
                                                              ##
                                                              ##  If the tuning_id is not found or equals to CLAP_INVALID_ID,
                                                              ##  then the function shall gracefuly return a sensible value.
                                                              ##
                                                              ##  sample_offset is the sample offset from the begining of the current process block.
                                                              ##
                                                              ##  should_play(...) should be checked before calling this function.
                                                              ##
                                                              ##  [audio-thread & in-process]
    ##  Returns true if the note should be played.
    ##  [audio-thread & in-process]
    shouldPlay*: proc (host: ptr ClapHostT; tuningId: ClapId; channel: int32T;
                     key: int32T): bool ##  Returns the number of tunings in the pool.
                                     ##  [main-thread]
    getTuningCount*: proc (host: ptr ClapHostT): uint32T ##  Gets info about a tuning
                                                   ##  [main-thread]
    getInfo*: proc (host: ptr ClapHostT; tuningIndex: uint32T;
                  info: ptr ClapTuningInfoT): bool

