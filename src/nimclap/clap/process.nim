import
  events, audio-buffer

const                         ##  Processing failed. The output buffer must be discarded.
  CLAP_PROCESS_ERROR* = 0       ##  Processing succeed, keep processing.
  CLAP_PROCESS_CONTINUE* = 1    ##  Processing succeed, keep processing if the output is not quiet.
  CLAP_PROCESS_CONTINUE_IF_NOT_QUIET* = 2 ##  Rely upon the plugin's tail to determine if the plugin should continue to process.
                                       ##  see clap_plugin_tail
  CLAP_PROCESS_TAIL* = 3 ##  Processing succeed, but no more processing is required,
                      ##  until next event or variation in audio input.
  CLAP_PROCESS_SLEEP* = 4

type
  ClapProcessStatus* = int32T
  ClapProcessT* {.bycopy.} = object
    steadyTime*: int64T ##  A steady sample time counter.
                      ##  This field can be used to calculate the sleep duration between two process calls.
                      ##  This value may be specific to this plugin instance and have no relation to what
                      ##  other plugin instances may receive.
                      ##
                      ##  Set to -1 if not available, otherwise the value must be greater or equal to 0,
                      ##  and must be increased by at least `frames_count` for the next call to process.
    ##  Number of frame to process
    framesCount*: uint32T      ##  time info at sample 0
                        ##  If null, then this is a free running host, no transport events will be provided
    transport*: ptr ClapEventTransportT ##  Audio buffers, they must have the same count as specified
                                     ##  by clap_plugin_audio_ports->get_count().
                                     ##  The index maps to clap_plugin_audio_ports->get_info().
    audioInputs*: ptr ClapAudioBufferT
    audioOutputs*: ptr ClapAudioBufferT
    audioInputsCount*: uint32T
    audioOutputsCount*: uint32T ##  Input and output events.
                              ##
                              ##  Events must be sorted by time.
                              ##  The input event list can't be modified.
    inEvents*: ptr ClapInputEventsT
    outEvents*: ptr ClapOutputEventsT

