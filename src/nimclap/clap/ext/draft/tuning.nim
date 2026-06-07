import ../../plugin, ../../events, ../../stringsizes, ../../host, ../../id

let extTuning*: cstring = cstring"clap.tuning/2"

type
  EventTuning* {.bycopy.} = object
    ## Use `HostEventRegistry.query(host, extTuning, spaceId)` to know the event
    ## space.
    ##
    ## This event defines the tuning to be used on the given port/channel.
    header*: EventHeader
    portIndex*: int16
      ## -1 global
    channel*: int16
      ## 0..15, -1 global
    tunningId*: Id

  TuningInfo* {.bycopy.} = object
    tuningId*: Id
    name*: array[name_Size, char]
    isDynamic*: bool
      ## true if the values may vary with time

  PluginTuning* {.bycopy.} = object
    changed*: proc(plugin: ptr Plugin) {.cdecl.}
      ## Called when a tuning is added or removed from the pool.
      ## `[main-thread]`

type HostTuning* {.bycopy.} = object
  ## This extension provides a dynamic tuning table to the plugin.
  getRelative*: proc(
    host: ptr Host, tuningId: Id, channel: int32, key: int32, sampleOffset: uint32
  ): cdouble {.cdecl.}
    ## Gets the relative tuning in semitones against equal temperament with
    ## A4=440Hz.
    ## The plugin may query the tuning at a rate that makes sense for *low*
    ## frequency modulations.
    ##
    ## If the `tuningId` is not found or equals to `invalidId`,
    ## then the function shall gracefully return a sensible value.
    ##
    ## `sampleOffset` is the sample offset from the beginning of the current
    ## process block.
    ##
    ## `shouldPlay` should be checked before calling this function.
    ##
    ## `[audio-thread & in-process]`
  shouldPlay*:
    proc(host: ptr Host, tuningId: Id, channel: int32, key: int32): bool {.cdecl.}
    ## Returns true if the note should be played.
    ## `[audio-thread & in-process]`
  getTuningCount*: proc(host: ptr Host): uint32 {.cdecl.}
    ## Returns the number of tunings in the pool.
    ## `[main-thread]`
  getInfo*:
    proc(host: ptr Host, tuningIndex: uint32, info: ptr TuningInfo): bool {.cdecl.}
    ## Gets info about a tuning
    ## Returns true on success and stores the result into `info`.
    ## `[main-thread]`
