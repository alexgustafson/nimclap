import
  events, audiobuffer

const                         ##  Processing failed. The output buffer must be discarded.
  CLAP_PROCESS_ERROR* = 0       ##  Processing succeeded, keep processing.
  CLAP_PROCESS_CONTINUE* = 1    ##  Processing succeeded, keep processing if the output is not quiet.
  CLAP_PROCESS_CONTINUE_IF_NOT_QUIET* = 2 ##  Rely upon the plugin's tail to determine if the plugin should continue to process.
                                       ##  see clap_plugin_tail
  CLAP_PROCESS_TAIL* = 3 ##  Processing succeeded, but no more processing is required,
                      ##  until the next event or variation in audio input.
  CLAP_PROCESS_SLEEP* = 4

type
  clap_process_status* = int32
  clap_process* {.bycopy.} = object
    ##  A steady sample time counter.
    ##  This field can be used to calculate the sleep duration between two process calls.
    ##  This value may be specific to this plugin instance and have no relation to what
    ##  other plugin instances may receive.
    ##
    ##  Set to -1 if not available, otherwise the value must be greater or equal to 0,
    ##  and must be increased by at least `frames_count` for the next call to process.
    steady_time*: int64
    ##  Number of frames to process
    frames_count*: uint32
    ##  time info at sample 0
    ##  If null, then this is a free running host, no transport events will be provided
    transport*: ptr clap_event_transport
    ##  Audio buffers, they must have the same count as specified
    ##  by clap_plugin_audio_ports->count().
    ##  The index maps to clap_plugin_audio_ports->get().
    ##  Input buffer and its contents are read-only.
    audio_inputs*: ptr UncheckedArray[clap_audio_buffer]
    audio_outputs*: ptr UncheckedArray[clap_audio_buffer]
    audio_inputs_count*: uint32
    audio_outputs_count*: uint32
    ##  The input event list can't be modified.
    ##  Input read-only event list. The host will deliver these sorted in sample order.
    in_events*: ptr clap_input_events
    ##  Output event list. The plugin must insert events in sample sorted order when inserting events
    out_events*: ptr clap_output_events

