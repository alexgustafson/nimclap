import events, audiobuffer

const ##  Processing failed. The output buffer must be discarded.
  processError* = 0 ##  Processing succeeded, keep processing.
  processContinue* = 1
    ##  Processing succeeded, keep processing if the output is not quiet.
  processContinueIfNotQuiet* = 2
    ##  Rely upon the plugin's tail to determine if the plugin should continue to process.
    ##  see clap_plugin_tail
  processTail* = 3
    ##  Processing succeeded, but no more processing is required,
    ##  until the next event or variation in audio input.
  processSleep* = 4

type
  ProcessStatus* = int32
  Process* {.bycopy.} = object
    ##  A steady sample time counter.
    ##  This field can be used to calculate the sleep duration between two process calls.
    ##  This value may be specific to this plugin instance and have no relation to what
    ##  other plugin instances may receive.
    ##
    ##  Set to -1 if not available, otherwise the value must be greater or equal to 0,
    ##  and must be increased by at least `frames_count` for the next call to process.
    steadyTime*: int64
    ##  Number of frames to process
    framesCount*: uint32
    ##  time info at sample 0
    ##  If null, then this is a free running host, no transport events will be provided
    transport*: ptr EventTransport
    ##  Audio buffers, they must have the same count as specified
    ##  by clap_plugin_audio_ports->count().
    ##  The index maps to clap_plugin_audio_ports->get().
    ##  Input buffer and its contents are read-only.
    audioInputs*: ptr UncheckedArray[AudioBuffer]
    audioOutputs*: ptr UncheckedArray[AudioBuffer]
    audioInputsCount*: uint32
    audioOutputsCount*: uint32
    ##  The input event list can't be modified.
    ##  Input read-only event list. The host will deliver these sorted in sample order.
    inEvents*: ptr InputEvents
    ##  Output event list. The plugin must insert events in sample sorted order when inserting events
    outEvents*: ptr OutputEvents
