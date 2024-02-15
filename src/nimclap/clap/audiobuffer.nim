import
  private/std

##  Sample code for reading a stereo buffer:
##
##  bool isLeftConstant = (buffer->constant_mask & (1 << 0)) != 0;
##  bool isRightConstant = (buffer->constant_mask & (1 << 1)) != 0;
##
##  for (int i = 0; i < N; ++i) {
##     float l = data32[0][isLeftConstant ? 0 : i];
##     float r = data32[1][isRightConstant ? 0 : i];
##  }
##
##  Note: checking the constant mask is optional, and this implies that
##  the buffer must be filled with the constant value.
##  Rationale: if a buffer reader doesn't check the constant mask, then it may
##  process garbage samples and in result, garbage samples may be transmitted
##  to the audio interface with all the bad consequences it can have.
##
##  The constant mask is a hint.

type
  clap_audio_buffer* {.bycopy.} = object
    ##  Either data32 or data64 pointer will be set.
    data32*: ptr UncheckedArray[UncheckedArray[cfloat]]
    data64*: ptr UncheckedArray[UncheckedArray[cdouble]]
    channel_count*: uint32
    latency*: uint32
    ##  latency from/to the audio interface
    constant_mask*: uint64

