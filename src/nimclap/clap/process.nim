import events, audiobuffer

const
  processError* = 0
    ## Processing failed. The output buffer must be discarded.
  processContinue* = 1
    ## Processing succeeded, keep processing.
  processContinueIfNotQuiet* = 2
    ## Processing succeeded, keep processing if the output is not quiet.
  processTail* = 3
    ## Rely upon the plugin's tail to determine if the plugin should continue to
    ## process. See `PluginTail` (the `ext/tail` extension).
  processSleep* = 4
    ## Processing succeeded, but no more processing is required until the next
    ## event or variation in audio input.

type
  ProcessStatus* = int32
  Process* {.bycopy.} = object
    steadyTime*: int64
      ## A steady sample time counter.
      ## This field can be used to calculate the sleep duration between two
      ## process calls. This value may be specific to this plugin instance and
      ## have no relation to what other plugin instances may receive.
      ##
      ## Set to -1 if not available, otherwise the value must be greater or equal
      ## to 0, and must be increased by at least `framesCount` for the next call
      ## to process.
    framesCount*: uint32
      ## Number of frames to process.
    transport*: ptr EventTransport
      ## Time info at sample 0.
      ## If nil, then this is a free running host: no transport events will be
      ## provided.
    audioInputs*: ptr UncheckedArray[AudioBuffer]
      ## Audio input buffers. The count must match `PluginAudioPorts.count`.
      ## The index maps to `PluginAudioPorts.get`.
      ## Input buffers and their contents are read-only.
    audioOutputs*: ptr UncheckedArray[AudioBuffer]
      ## Audio output buffers. The count must match `PluginAudioPorts.count`.
    audioInputsCount*: uint32
    audioOutputsCount*: uint32
    inEvents*: ptr InputEvents
      ## Input read-only event list. The host delivers these sorted in sample
      ## order; it cannot be modified.
    outEvents*: ptr OutputEvents
      ## Output event list. The plugin must insert events in sample-sorted order.
