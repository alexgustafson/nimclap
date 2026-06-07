import fixedpoint, id

type EventHeader* {.bycopy.} = object
  ## event header
  ## All clap events start with an event header to determine the overall
  ## size of the event and its type and space (a namespacing for types).
  ## clap event objects are contiguous regions of memory which can be copied
  ## with a memcpy of `size` bytes starting at the top of the header. As
  ## such, be very careful when designing clap events with internal pointers
  ## and other non-value-types to consider the lifetime of those members.
  size*: uint32
    ## event size including this header, eg: `sizeof(EventNote)`
  time*: uint32
    ## sample offset within the buffer for this event
  spaceId*: uint16
    ## event space, see `HostEventRegistry`
  `type`*: uint16
    ## event type
  flags*: uint32
    ## see `EventFlags`

let coreEventSpaceId*: uint16 = 0
  ## The clap core event space.

type EventFlags* {.pure.} = enum
  isLive = 1 shl 0
    ## Indicate a live user event, for example a user turning a physical knob
    ## or playing a physical key.
  dontRecord = 1 shl 1
    ## Indicate that the event should not be recorded.
    ## For example this is useful when a parameter changes because of a MIDI CC,
    ## because if the host records both the MIDI CC automation and the parameter
    ## automation there will be a conflict.

const
  eventNoteOn* = 0
    ## Some of the following events overlap, a note on can be expressed with:
    ## - `eventNoteOn`
    ## - `eventMidi`
    ## - `eventMidi2`
    ##
    ## The preferred way of sending a note event is to use the `eventNote*`
    ## values.
    ##
    ## The same event must not be sent twice: it is forbidden to send the same
    ## note on encoded with both `eventNoteOn` and `eventMidi`.
    ##
    ## The plugins are encouraged to be able to handle note events encoded as
    ## raw midi or midi2, or implement `PluginEventFilter` and reject raw midi
    ## and midi2 events.
    ##
    ## `eventNoteOn` and `eventNoteOff` represent a key pressed and key released
    ## event, respectively. An `eventNoteOn` with a velocity of 0 is valid and
    ## should not be interpreted as an `eventNoteOff`.
    ##
    ## `eventNoteChoke` is meant to choke the voice(s), like in a drum machine
    ## when a closed hihat chokes an open hihat. This event can be sent by the
    ## host to the plugin. Here are two use cases:
    ## - a plugin is inside a drum pad in Bitwig Studio's drum machine, and this
    ##   pad is choked by another one
    ## - the user double-clicks the DAW's stop button in the transport which then
    ##   stops the sound on every track
    ##
    ## `eventNoteEnd` is sent by the plugin to the host. The port, channel, key
    ## and note_id are those given by the host in the `eventNoteOn` event. In
    ## other words, this event is matched against the plugin's note input port.
    ## `eventNoteEnd` is useful to help the host to match the plugin's voice
    ## life time.
    ##
    ## When using polyphonic modulations, the host has to allocate and release
    ## voices for its polyphonic modulator. Yet only the plugin effectively knows
    ## when the host should terminate a voice. `eventNoteEnd` solves that issue in
    ## a non-intrusive and cooperative way.
    ##
    ## CLAP assumes that the host will allocate a unique voice on `eventNoteOn`
    ## event for a given port, channel and key. This voice will run until the
    ## plugin will instruct the host to terminate it by sending an `eventNoteEnd`
    ## event.
    ##
    ## Consider the following sequence:
    ## - process()
    ##    Host->Plugin NoteOn(port:0, channel:0, key:16, time:t0)
    ##    Host->Plugin NoteOn(port:0, channel:0, key:64, time:t0)
    ##    Host->Plugin NoteOff(port:0, channel:0, key:16, t1)
    ##    Host->Plugin NoteOff(port:0, channel:0, key:64, t1)
    ##    # on t2, both notes did terminate
    ##    Host->Plugin NoteOn(port:0, channel:0, key:64, t3)
    ##    # Here the plugin finished processing all the frames and will tell the host
    ##    # to terminate the voice on key 16 but not 64, because a note has been started at t3
    ##    Plugin->Host NoteEnd(port:0, channel:0, key:16, time:ignored)
    ##
    ## These four events use `EventNote`.
  eventNoteOff* = 1
  eventNoteChoke* = 2
  eventNoteEnd* = 3
  eventNoteExpression* = 4
    ## Represents a note expression.
    ## Uses `EventNoteExpression`.
  eventParamValue* = 5
    ## `eventParamValue` sets the parameter's value; uses `EventParamValue`.
    ## `eventParamMod` sets the parameter's modulation amount; uses
    ## `EventParamMod`.
    ##
    ## The value heard is: param_value + param_mod.
    ##
    ## In case of a concurrent global value/modulation versus a polyphonic one,
    ## the voice should only use the polyphonic one and the polyphonic modulation
    ## amount will already include the monophonic signal.
  eventParamMod* = 6
  eventParamGestureBegin* = 7
    ## Indicates that the user started or finished adjusting a knob.
    ## This is not mandatory to wrap parameter changes with gesture events, but
    ## this improves the user experience a lot when recording automation or
    ## overriding automation playback.
    ## Uses `EventParamGesture`.
  eventParamGestureEnd* = 8
  eventTransport* = 9
    ## update the transport info; `EventTransport`
  eventMidi* = 10
    ## raw midi event; `EventMidi`
  eventMidiSysex* = 11
    ## raw midi sysex event; `EventMidiSysex`
  eventMidi2* = 12
    ## raw midi 2 event; `EventMidi2`

type EventNote* {.bycopy.} = object
  ## Note on, off, end and choke events.
  ##
  ## Clap addresses notes and voices using the 4-value tuple
  ## (port, channel, key, note_id). Note on/off/end/choke
  ## events and parameter modulation messages are delivered with
  ## these values populated.
  ##
  ## Values in a note and voice address are either >= 0 if they
  ## are specified, or -1 to indicate a wildcard. A wildcard
  ## means a voice with any value in that part of the tuple
  ## matches the message.
  ##
  ## For instance, a (PCKN) of (0, 3, -1, -1) will match all voices
  ## on channel 3 of port 0. And a PCKN of (-1, 0, 60, -1) will match
  ## all channel 0 key 60 voices, independent of port or note id.
  ##
  ## Especially in the case of note-on note-off pairs, and in the
  ## absence of voice stacking or polyphonic modulation, a host may
  ## choose to issue a note id only at note on. So you may see a
  ## message stream like
  ##
  ## `eventNoteOn  [0,0,60,184]`
  ## `eventNoteOff [0,0,60,-1]`
  ##
  ## and the host will expect the first voice to be released.
  ## Well constructed plugins will search for voices and notes using
  ## the entire tuple.
  ##
  ## In the case of note on events:
  ## - The port, channel and key must be specified with a value >= 0
  ## - A note-on event with a '-1' for port, channel or key is invalid and
  ##   can be rejected or ignored by a plugin or host.
  ## - A host which does not support note ids should set the note id to -1.
  ##
  ## In the case of note choke or end events:
  ## - the velocity is ignored.
  ## - key and channel are used to match active notes
  ## - note_id is optionally provided by the host
  header*: EventHeader
  noteId*: int32
    ## host provided note id >= 0, or -1 if unspecified or wildcard
  portIndex*: int16
    ## port index from the `noteports` extension; -1 for wildcard
  channel*: int16
    ## 0..15, same as MIDI1 Channel Number, -1 for wildcard
  key*: int16
    ## 0..127, same as MIDI1 Key Number (60==Middle C), -1 for wildcard
  velocity*: cdouble
    ## 0..1

const
  noteExpressionVolume* = 0
    ## Note Expressions are well named modifications of a voice targeted to
    ## voices using the same wildcard rules described above. Note Expressions are
    ## delivered as sample accurate events and should be applied at the sample
    ## when received.
    ##
    ## Note expressions are a statement of value, not cumulative. A PAN event of 0
    ## followed by 1 followed by 0.5 would pan hard left, hard right, and center.
    ## They are intended as an offset from the non-note-expression voice default.
    ## A voice which had a volume of -20db absent note expressions which received a
    ## +4db note expression would move the voice to -16db.
    ##
    ## A plugin which receives a note expression at the same sample as an
    ## `eventNoteOn` event should apply that expression to all generated samples.
    ## A plugin which receives a note expression after an `eventNoteOn` event
    ## should initiate the voice with default values and then apply the note
    ## expression when received. A plugin may make a choice to smooth note
    ## expression streams.
    ##
    ## with 0 < x <= 4, plain = 20 * log(x)
  noteExpressionPan* = 1
    ## pan, 0 left, 0.5 center, 1 right
  noteExpressionTuning* = 2
    ## Relative tuning in semitones, from -120 to +120. Semitones are in
    ## equal temperament and are doubles; the resulting note would be
    ## retuned by `100 * evt.value` cents.
  noteExpressionVibrato* = 3
    ## 0..1
  noteExpressionExpression* = 4
  noteExpressionBrightness* = 5
  noteExpressionPressure* = 6

type
  NoteExpression* = int32
  EventNoteExpression* {.bycopy.} = object
    header*: EventHeader
    expressionId*: NoteExpression
    noteId*: int32
      ## target a specific note_id, port, key and channel, with
      ## -1 meaning wildcard, per the wildcard discussion above
    portIndex*: int16
    channel*: int16
    key*: int16
    value*: cdouble
      ## see expression for the range

  EventParamValue* {.bycopy.} = object
    header*: EventHeader
    paramId*: Id
      ## target parameter
      ## See `ParamInfo.id`.
    cookie*: pointer
      ## See `ParamInfo.cookie`.
    noteId*: int32
      ## target a specific note_id, port, key and channel, with
      ## -1 meaning wildcard, per the wildcard discussion above
    portIndex*: int16
    channel*: int16
    key*: int16
    value*: cdouble

  EventParamMod* {.bycopy.} = object
    header*: EventHeader
    paramId*: Id
      ## target parameter
      ## See `ParamInfo.id`.
    cookie*: pointer
      ## See `ParamInfo.cookie`.
    noteId*: int32
      ## target a specific note_id, port, key and channel, with
      ## -1 meaning wildcard, per the wildcard discussion above
    portIndex*: int16
    channel*: int16
    key*: int16
    amount*: cdouble
      ## modulation amount

  EventParamGesture* {.bycopy.} = object
    header*: EventHeader
    paramId*: Id
      ## target parameter
      ## See `ParamInfo.id`.

  transportflags* = enum
    hasTempo = 1 shl 0
    hasBeatsTimeline = 1 shl 1
    hasSecondsTimeline = 1 shl 2
    hasTimeSignature = 1 shl 3
    isPlaying = 1 shl 4
    isRecording = 1 shl 5
    isLoopActive = 1 shl 6
    isWithinPreRoll = 1 shl 7

type
  EventTransport* {.bycopy.} = object
    ## `EventTransport` provides song position, tempo, and similar information
    ## from the host to the plugin. There are two ways a host communicates these
    ## values. In the `Process` structure sent to each processing block, the host
    ## may provide a transport structure which indicates the available information
    ## at the start of the block. If the host provides sample-accurate tempo or
    ## transport changes, it can also provide subsequent inter-block transport
    ## updates by delivering a new event.
    header*: EventHeader
    flags*: uint32
      ## see `transportflags`
    songPosBeats*: Beattime
      ## position in beats
    songPosSeconds*: Sectime
      ## position in seconds
    tempo*: cdouble
      ## in bpm
    tempoInc*: cdouble
      ## tempo increment for each sample and until the next
      ## time info event
    loopStartBeats*: Beattime
    loopEndBeats*: Beattime
    loopStartSeconds*: Sectime
    loopEndSeconds*: Sectime
    barStart*: Beattime
      ## start pos of the current bar
    barNumber*: int32
      ## bar at song pos 0 has the number 0
    tsigNum*: uint16
      ## time signature numerator
    tsigDenom*: uint16
      ## time signature denominator

  EventMidi* {.bycopy.} = object
    header*: EventHeader
    portIndex*: uint16
    data*: array[3, uint8]

type EventMidiSysex* {.bycopy.} = object
  ## `EventMidiSysex` contains a pointer to a sysex contents buffer.
  ## The lifetime of this buffer is (from host->plugin) only the process
  ## call in which the event is delivered or (from plugin->host) only the
  ## duration of a `tryPush` call.
  ##
  ## Since `OutputEvents.tryPush` requires hosts to make a copy of
  ## an event, host implementers receiving sysex messages from plugins need
  ## to take care to both copy the event (so header, size, etc...) but
  ## also memcpy the contents of the sysex pointer to host-owned memory, and
  ## not just copy the data pointer.
  ##
  ## Similarly plugins retaining the sysex outside the lifetime of a single
  ## process call must copy the sysex buffer to plugin-owned memory.
  ##
  ## As a consequence, the data structure pointed to by the sysex buffer
  ## must be contiguous and copyable with `memcpy` of `size` bytes.
  header*: EventHeader
  portIndex*: uint16
  buffer*: ptr uint8
    ## midi buffer. See lifetime comment above.
  size*: uint32

type EventMidi2* {.bycopy.} = object
  ## While it is possible to use a series of midi2 event to send a sysex,
  ## prefer `EventMidiSysex` if possible for efficiency.
  header*: EventHeader
  portIndex*: uint16
  data*: array[4, uint32]

type InputEvents* {.bycopy.} = object
  ## Input event list. The host will deliver these sorted in sample order.
  ctx*: pointer
    ## reserved pointer for the list
  size*: proc(list: ptr InputEvents): uint32 {.cdecl.}
    ## returns the number of events in the list
  get*: proc(list: ptr InputEvents, index: uint32): ptr EventHeader {.cdecl.}
    ## Don't free the returned event, it belongs to the list

type OutputEvents* {.bycopy.} = object
  ## Output event list. The plugin must insert events in sample sorted order
  ## when inserting events.
  ctx*: pointer
    ## reserved pointer for the list
  tryPush*: proc(list: ptr OutputEvents, event: ptr EventHeader): bool {.cdecl.}
    ## Pushes a copy of the event.
    ## returns false if the event could not be pushed to the queue (out of memory?)
