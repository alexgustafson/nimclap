type AudioBuffer* {.bycopy.} = object
  ## Audio buffer for one port, holding either 32-bit or 64-bit sample data.
  ##
  ## Sample code for reading a stereo buffer:
  ##
  ## ```
  ## let isLeftConstant = (buffer.constantMask and (1 shl 0)) != 0
  ## let isRightConstant = (buffer.constantMask and (1 shl 1)) != 0
  ##
  ## for i in 0 ..< N:
  ##   let l = buffer.data32[0][if isLeftConstant: 0 else: i]
  ##   let r = buffer.data32[1][if isRightConstant: 0 else: i]
  ## ```
  ##
  ## Note: checking the constant mask is optional, and this implies that the
  ## buffer must be filled with the constant value.
  ## Rationale: if a buffer reader doesn't check the constant mask, then it may
  ## process garbage samples and in result, garbage samples may be transmitted
  ## to the audio interface with all the bad consequences it can have.
  ##
  ## The constant mask is a hint.
  data32*: ptr UncheckedArray[ptr UncheckedArray[cfloat]]
    ## Either `data32` or `data64` pointer will be set.
  data64*:  ptr UncheckedArray[ptr UncheckedArray[cdouble]]
  channelCount*: uint32
  latency*: uint32
    ## Latency from/to the audio interface.
  constantMask*: uint64
