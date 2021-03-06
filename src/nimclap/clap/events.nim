import
  private/std, fixedpoint, id

##  event header
##  must be the first attribute of the event

type
  ClapEventHeaderT* {.bycopy.} = object
    size*: uint32T             ##  event size including this header, eg: sizeof (clap_event_note)
    time*: uint32T             ##  sample offset within the buffer for this event
    spaceId*: uint16T          ##  event space, see clap_host_event_registry
    `type`*: uint16T           ##  event type
    flags*: uint32T            ##  see clap_event_flags


##  The clap core event space

var CLAP_CORE_EVENT_SPACE_ID*: uint16T = 0

type
  ClapEventFlags* = enum ##  Indicate a live user event, for example a user turning a phisical knob
                      ##  or playing a physical key.
    CLAP_EVENT_IS_LIVE = 1 shl 0, ##  Indicate that the event should not be recorded.
                             ##  For example this is useful when a parameter changes because of a MIDI CC,
                             ##  because if the host records both the MIDI CC automation and the parameter
                             ##  automation there will be a conflict.
    CLAP_EVENT_DONT_RECORD = 1 shl 1


##  Some of the following events overlap, a note on can be expressed with:
##  - CLAP_EVENT_NOTE_ON
##  - CLAP_EVENT_MIDI
##  - CLAP_EVENT_MIDI2
##
##  The preferred way of sending a note event is to use CLAP_EVENT_NOTE_*.
##
##  The same event must not be sent twice: it is forbidden to send a the same note on
##  encoded with both CLAP_EVENT_NOTE_ON and CLAP_EVENT_MIDI.
##
##  The plugins are encouraged to be able to handle note events encoded as raw midi or midi2,
##  or implement clap_plugin_event_filter and reject raw midi and midi2 events.

const ##  NOTE_ON and NOTE_OFF represents a key pressed and key released event.
     ##  A NOTE_ON with a velocity of 0 is valid and should not be interpreted as a NOTE_OFF.
     ##
     ##  NOTE_CHOKE is meant to choke the voice(s), like in a drum machine when a closed hihat
     ##  chokes an open hihat. This event can be sent by the host to the plugin. Here two use case:
     ##  - a plugin is inside a drum pad in Bitwig Studio's drum machine, and this pad is choked by
     ##    another one
     ##  - the user double clicks the DAW's stop button in the transport which then stops the sound on
     ##    every tracks
     ##
     ##  NOTE_END is sent by the plugin to the host. The port, channel, key and note_id are those given
     ##  by the host in the NOTE_ON event. In other words, this event is matched against the
     ##  plugin's note input port.
     ##  NOTE_END is useful to help the host to match the plugin's voice life time.
     ##
     ##  When using polyphonic modulations, the host has to allocate and release voices for its
     ##  polyphonic modulator. Yet only the plugin effectively knows when the host should terminate
     ##  a voice. NOTE_END solves that issue in a non-intrusive and cooperative way.
     ##
     ##  CLAP assumes that the host will allocate a unique voice on NOTE_ON event for a given port,
     ##  channel and key. This voice will run until the plugin will instruct the host to terminate
     ##  it by sending a NOTE_END event.
     ##
     ##  Consider the following sequence:
     ##  - process()
     ##     Host->Plugin NoteOn(port:0, channel:0, key:16, time:t0)
     ##     Host->Plugin NoteOn(port:0, channel:0, key:64, time:t0)
     ##     Host->Plugin NoteOff(port:0, channel:0, key:16, t1)
     ##     Host->Plugin NoteOff(port:0, channel:0, key:64, t1)
     ##     # on t2, both notes did terminate
     ##     Host->Plugin NoteOn(port:0, channel:0, key:64, t3)
     ##     # Here the plugin finished to process all the frames and will tell the host
     ##     # to terminate the voice on key 16 but not 64, because a note has been started at t3
     ##     Plugin->Host NoteEnd(port:0, channel:0, key:16, time:ignored)
     ##
     ##  Those four events use clap_event_note.
  CLAP_EVENT_NOTE_ON* = 0
  CLAP_EVENT_NOTE_OFF* = 1
  CLAP_EVENT_NOTE_CHOKE* = 2
  CLAP_EVENT_NOTE_END* = 3      ##  Represents a note expression.
                        ##  Uses clap_event_note_expression.
  CLAP_EVENT_NOTE_EXPRESSION* = 4 ##  PARAM_VALUE sets the parameter's value; uses clap_event_param_value.
                               ##  PARAM_MOD sets the parameter's modulation amount; uses clap_event_param_mod.
                               ##
                               ##  The value heard is: param_value + param_mod.
                               ##
                               ##  In case of a concurrent global value/modulation versus a polyphonic one,
                               ##  the voice should only use the polyphonic one and the polyphonic modulation
                               ##  amount will already include the monophonic signal.
  CLAP_EVENT_PARAM_VALUE* = 5
  CLAP_EVENT_PARAM_MOD* = 6 ##  Indicates that the user started or finished to adjust a knob.
                         ##  This is not mandatory to wrap parameter changes with gesture events, but this improves a lot
                         ##  the user experience when recording automation or overriding automation playback.
                         ##  Uses clap_event_param_gesture.
  CLAP_EVENT_PARAM_GESTURE_BEGIN* = 7
  CLAP_EVENT_PARAM_GESTURE_END* = 8
  CLAP_EVENT_TRANSPORT* = 9     ##  update the transport info; clap_event_transport
  CLAP_EVENT_MIDI* = 10         ##  raw midi event; clap_event_midi
  CLAP_EVENT_MIDI_SYSEX* = 11   ##  raw midi sysex event; clap_event_midi_sysex
  CLAP_EVENT_MIDI2* = 12        ##  raw midi 2 event; clap_event_midi2

##  Note on, off, end and choke events.
##  In the case of note choke or end events:
##  - the velocity is ignored.
##  - key and channel are used to match active notes, a value of -1 matches all.

type
  ClapEventNoteT* {.bycopy.} = object
    header*: ClapEventHeaderT
    noteId*: int32T            ##  -1 if unspecified, otherwise >=0
    portIndex*: int16T
    channel*: int16T           ##  0..15
    key*: int16T               ##  0..127
    velocity*: cdouble         ##  0..1


const                         ##  with 0 < x <= 4, plain = 20 * log(x)
  CLAP_NOTE_EXPRESSION_VOLUME* = 0 ##  pan, 0 left, 0.5 center, 1 right
  CLAP_NOTE_EXPRESSION_PAN* = 1 ##  relative tuning in semitone, from -120 to +120
  CLAP_NOTE_EXPRESSION_TUNING* = 2 ##  0..1
  CLAP_NOTE_EXPRESSION_VIBRATO* = 3
  CLAP_NOTE_EXPRESSION_EXPRESSION* = 4
  CLAP_NOTE_EXPRESSION_BRIGHTNESS* = 5
  CLAP_NOTE_EXPRESSION_PRESSURE* = 6

type
  ClapNoteExpression* = int32T
  ClapEventNoteExpressionT* {.bycopy.} = object
    header*: ClapEventHeaderT
    expressionId*: ClapNoteExpression ##  target a specific note_id, port, key and channel, -1 for global
    noteId*: int32T
    portIndex*: int16T
    channel*: int16T
    key*: int16T
    value*: cdouble            ##  see expression for the range

  ClapEventParamValueT* {.bycopy.} = object
    header*: ClapEventHeaderT  ##  target parameter
    paramId*: ClapId           ##  @ref clap_param_info.id
    cookie*: pointer           ##  @ref clap_param_info.cookie
                   ##  target a specific note_id, port, key and channel, -1 for global
    noteId*: int32T
    portIndex*: int16T
    channel*: int16T
    key*: int16T
    value*: cdouble

  ClapEventParamModT* {.bycopy.} = object
    header*: ClapEventHeaderT  ##  target parameter
    paramId*: ClapId           ##  @ref clap_param_info.id
    cookie*: pointer           ##  @ref clap_param_info.cookie
                   ##  target a specific note_id, port, key and channel, -1 for global
    noteId*: int32T
    portIndex*: int16T
    channel*: int16T
    key*: int16T
    amount*: cdouble           ##  modulation amount

  ClapEventParamGestureT* {.bycopy.} = object
    header*: ClapEventHeaderT  ##  target parameter
    paramId*: ClapId           ##  @ref clap_param_info.id

  ClapTransportFlags* = enum
    CLAP_TRANSPORT_HAS_TEMPO = 1 shl 0, CLAP_TRANSPORT_HAS_BEATS_TIMELINE = 1 shl 1,
    CLAP_TRANSPORT_HAS_SECONDS_TIMELINE = 1 shl 2,
    CLAP_TRANSPORT_HAS_TIME_SIGNATURE = 1 shl 3, CLAP_TRANSPORT_IS_PLAYING = 1 shl 4,
    CLAP_TRANSPORT_IS_RECORDING = 1 shl 5, CLAP_TRANSPORT_IS_LOOP_ACTIVE = 1 shl 6,
    CLAP_TRANSPORT_IS_WITHIN_PRE_ROLL = 1 shl 7


type
  ClapEventTransportT* {.bycopy.} = object
    header*: ClapEventHeaderT
    flags*: uint32T            ##  see clap_transport_flags
    songPosBeats*: ClapBeattime ##  position in beats
    songPosSeconds*: ClapSectime ##  position in seconds
    tempo*: cdouble            ##  in bpm
    tempoInc*: cdouble ##  tempo increment for each samples and until the next
                     ##  time info event
    loopStartBeats*: ClapBeattime
    loopEndBeats*: ClapBeattime
    loopStartSeconds*: ClapSectime
    loopEndSeconds*: ClapSectime
    barStart*: ClapBeattime    ##  start pos of the current bar
    barNumber*: int32T         ##  bar at song pos 0 has the number 0
    tsigNum*: uint16T          ##  time signature numerator
    tsigDenom*: uint16T        ##  time signature denominator

  ClapEventMidiT* {.bycopy.} = object
    header*: ClapEventHeaderT
    portIndex*: uint16T
    data*: array[3, uint8T]

  ClapEventMidiSysexT* {.bycopy.} = object
    header*: ClapEventHeaderT
    portIndex*: uint16T
    buffer*: ptr uint8T         ##  midi buffer
    size*: uint32T


##  While it is possible to use a series of midi2 event to send a sysex,
##  prefer clap_event_midi_sysex if possible for efficiency.

type
  ClapEventMidi2T* {.bycopy.} = object
    header*: ClapEventHeaderT
    portIndex*: uint16T
    data*: array[4, uint32T]


##  Input event list, events must be sorted by time.

type
  ClapInputEventsT* {.bycopy.} = object
    ctx*: pointer              ##  reserved pointer for the list
    size*: proc (list: ptr ClapInputEvents): uint32T ##  Don't free the returned event, it belongs to the list
    get*: proc (list: ptr ClapInputEvents; index: uint32T): ptr ClapEventHeaderT


##  Output event list, events must be sorted by time.

type
  ClapOutputEventsT* {.bycopy.} = object
    ctx*: pointer              ##  reserved pointer for the list
                ##  Pushes a copy of the event
                ##  returns false if the event could not be pushed to the queue (out of memory?)
    tryPush*: proc (list: ptr ClapOutputEvents; event: ptr ClapEventHeaderT): bool

