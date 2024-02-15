import
  private/std, fixedpoint, id

##  event header
##  must be the first attribute of the event

type
  clap_event_header* {.bycopy.} = object
    size*: uint32
    ##  event size including this header, eg: sizeof (clap_event_note)
    time*: uint32
    ##  sample offset within the buffer for this event
    space_id*: uint16
    ##  event space, see clap_host_event_registry
    `type`*: uint16
    ##  event type
    flags*: uint32
    ##  see clap_event_flags


##  The clap core event space

let CLAP_CORE_EVENT_SPACE_ID*: uint16 = 0

type
  clap_event_flags* = enum ##  Indicate a live user event, for example a user turning a physical knob
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

const ##  NOTE_ON and NOTE_OFF represent a key pressed and key released event, respectively.
     ##  A NOTE_ON with a velocity of 0 is valid and should not be interpreted as a NOTE_OFF.
     ##
     ##  NOTE_CHOKE is meant to choke the voice(s), like in a drum machine when a closed hihat
     ##  chokes an open hihat. This event can be sent by the host to the plugin. Here are two use
     ##  cases:
     ##  - a plugin is inside a drum pad in Bitwig Studio's drum machine, and this pad is choked by
     ##    another one
     ##  - the user double-clicks the DAW's stop button in the transport which then stops the sound on
     ##    every track
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
     ##     # Here the plugin finished processing all the frames and will tell the host
     ##     # to terminate the voice on key 16 but not 64, because a note has been started at t3
     ##     Plugin->Host NoteEnd(port:0, channel:0, key:16, time:ignored)
     ##
     ##  These four events use clap_event_note.
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
  CLAP_EVENT_PARAM_MOD* = 6 ##  Indicates that the user started or finished adjusting a knob.
                         ##  This is not mandatory to wrap parameter changes with gesture events, but this improves
                         ##  the user experience a lot when recording automation or overriding automation playback.
                         ##  Uses clap_event_param_gesture.
  CLAP_EVENT_PARAM_GESTURE_BEGIN* = 7
  CLAP_EVENT_PARAM_GESTURE_END* = 8
  CLAP_EVENT_TRANSPORT* = 9     ##  update the transport info; clap_event_transport
  CLAP_EVENT_MIDI* = 10         ##  raw midi event; clap_event_midi
  CLAP_EVENT_MIDI_SYSEX* = 11   ##  raw midi sysex event; clap_event_midi_sysex
  CLAP_EVENT_MIDI2* = 12        ##  raw midi 2 event; clap_event_midi2

##  Note on, off, end and choke events.
##
##  Clap addresses notes and voices using the 4-value tuple
##  (port, channel, key, note_id). Note on/off/end/choke
##  events and parameter modulation messages are delivered with
##  these values populated.
##
##  Values in a note and voice address are either >= 0 if they
##  are specified, or -1 to indicate a wildcard. A wildcard
##  means a voice with any value in that part of the tuple
##  matches the message.
##
##  For instance, a (PCKN) of (0, 3, -1, -1) will match all voices
##  on channel 3 of port 0. And a PCKN of (-1, 0, 60, -1) will match
##  all channel 0 key 60 voices, independent of port or note id.
##
##  Especially in the case of note-on note-off pairs, and in the
##  absence of voice stacking or polyphonic modulation, a host may
##  choose to issue a note id only at note on. So you may see a
##  message stream like
##
##  CLAP_EVENT_NOTE_ON  [0,0,60,184]
##  CLAP_EVENT_NOTE_OFF [0,0,60,-1]
##
##  and the host will expect the first voice to be released.
##  Well constructed plugins will search for voices and notes using
##  the entire tuple.
##
##  In the case of note choke or end events:
##  - the velocity is ignored.
##  - key and channel are used to match active notes
##  - note_id is optionally provided by the host

type
  clap_event_note* {.bycopy.} = object
    header*: clap_event_header
    note_id*: int32
    ##  host provided note id >= 0, or -1 if unspecified or wildcard
    port_index*: int16
    ##  port index from ext/note-ports; -1 for wildcard
    channel*: int16
    ##  0..15, same as MIDI1 Channel Number, -1 for wildcard
    key*: int16
    ##  0..127, same as MIDI1 Key Number (60==Middle C), -1 for wildcard
    velocity*: cdouble
    ##  0..1


##  Note Expressions are well named modifications of a voice targeted to
##  voices using the same wildcard rules described above. Note Expressions are delivered
##  as sample accurate events and should be applied at the sample when received.
##
##  Note expressions are a statement of value, not cumulative. A PAN event of 0 followed by 1
##  followed by 0.5 would pan hard left, hard right, and center. They are intended as
##  an offset from the non-note-expression voice default. A voice which had a volume of
##  -20db absent note expressions which received a +4db note expression would move the
##  voice to -16db.
##
##  A plugin which receives a note expression at the same sample as a NOTE_ON event
##  should apply that expression to all generated samples. A plugin which receives
##  a note expression after a NOTE_ON event should initiate the voice with default
##  values and then apply the note expression when received. A plugin may make a choice
##  to smooth note expression streams.

const                         ##  with 0 < x <= 4, plain = 20 * log(x)
  CLAP_NOTE_EXPRESSION_VOLUME* = 0 ##  pan, 0 left, 0.5 center, 1 right
  CLAP_NOTE_EXPRESSION_PAN* = 1 ##  Relative tuning in semitones, from -120 to +120. Semitones are in
                             ##  equal temperament and are doubles; the resulting note would be
                             ##  retuned by `100 * evt->value` cents.
  CLAP_NOTE_EXPRESSION_TUNING* = 2 ##  0..1
  CLAP_NOTE_EXPRESSION_VIBRATO* = 3
  CLAP_NOTE_EXPRESSION_EXPRESSION* = 4
  CLAP_NOTE_EXPRESSION_BRIGHTNESS* = 5
  CLAP_NOTE_EXPRESSION_PRESSURE* = 6

type
  clap_note_expression* = int32
  clap_event_note_expression* {.bycopy.} = object
    header*: clap_event_header
    expression_id*: clap_note_expression
    ##  target a specific note_id, port, key and channel, with
    ##  -1 meaning wildcard, per the wildcard discussion above
    note_id*: int32
    port_index*: int16
    channel*: int16
    key*: int16
    value*: cdouble
    ##  see expression for the range

  clap_event_param_value* {.bycopy.} = object
    header*: clap_event_header
    ##  target parameter
    param_id*: clap_id
    ##  @ref clap_param_info.id
    cookie*: pointer
    ##  @ref clap_param_info.cookie
    ##  target a specific note_id, port, key and channel, with
    ##  -1 meaning wildcard, per the wildcard discussion above
    note_id*: int32
    port_index*: int16
    channel*: int16
    key*: int16
    value*: cdouble

  clap_event_param_mod* {.bycopy.} = object
    header*: clap_event_header
    ##  target parameter
    param_id*: clap_id
    ##  @ref clap_param_info.id
    cookie*: pointer
    ##  @ref clap_param_info.cookie
    ##  target a specific note_id, port, key and channel, with
    ##  -1 meaning wildcard, per the wildcard discussion above
    note_id*: int32
    port_index*: int16
    channel*: int16
    key*: int16
    amount*: cdouble
    ##  modulation amount

  clap_event_param_gesture* {.bycopy.} = object
    header*: clap_event_header
    ##  target parameter
    param_id*: clap_id
    ##  @ref clap_param_info.id

  clap_transport_flags* = enum
    CLAP_TRANSPORT_HAS_TEMPO = 1 shl 0, CLAP_TRANSPORT_HAS_BEATS_TIMELINE = 1 shl 1,
    CLAP_TRANSPORT_HAS_SECONDS_TIMELINE = 1 shl 2,
    CLAP_TRANSPORT_HAS_TIME_SIGNATURE = 1 shl 3, CLAP_TRANSPORT_IS_PLAYING = 1 shl 4,
    CLAP_TRANSPORT_IS_RECORDING = 1 shl 5, CLAP_TRANSPORT_IS_LOOP_ACTIVE = 1 shl 6,
    CLAP_TRANSPORT_IS_WITHIN_PRE_ROLL = 1 shl 7


type
  clap_event_transport* {.bycopy.} = object
    header*: clap_event_header
    flags*: uint32
    ##  see clap_transport_flags
    song_pos_beats*: clap_beattime
    ##  position in beats
    song_pos_seconds*: clap_sectime
    ##  position in seconds
    tempo*: cdouble
    ##  in bpm
    tempo_inc*: cdouble
    ##  tempo increment for each sample and until the next
    ##  time info event
    loop_start_beats*: clap_beattime
    loop_end_beats*: clap_beattime
    loop_start_seconds*: clap_sectime
    loop_end_seconds*: clap_sectime
    bar_start*: clap_beattime
    ##  start pos of the current bar
    bar_number*: int32
    ##  bar at song pos 0 has the number 0
    tsig_num*: uint16
    ##  time signature numerator
    tsig_denom*: uint16
    ##  time signature denominator

  clap_event_midi* {.bycopy.} = object
    header*: clap_event_header
    port_index*: uint16
    data*: array[3, uint8]

  clap_event_midi_sysex* {.bycopy.} = object
    header*: clap_event_header
    port_index*: uint16
    buffer*: ptr uint8
    ##  midi buffer
    size*: uint32


##  While it is possible to use a series of midi2 event to send a sysex,
##  prefer clap_event_midi_sysex if possible for efficiency.

type
  clap_event_midi2* {.bycopy.} = object
    header*: clap_event_header
    port_index*: uint16
    data*: array[4, uint32]


##  Input event list. The host will deliver these sorted in sample order.

type
  clap_input_events* {.bycopy.} = object
    ctx*: pointer
    ##  reserved pointer for the list
    ##  returns the number of events in the list
    size*: proc (list: ptr clap_input_events): uint32 {.cdecl.}
    ##  Don't free the returned event, it belongs to the list
    get*: proc (list: ptr clap_input_events; index: uint32): ptr clap_event_header {.
        cdecl.}


##  Output event list. The plugin must insert events in sample sorted order when inserting events

type
  clap_output_events* {.bycopy.} = object
    ctx*: pointer
    ##  reserved pointer for the list
    ##  Pushes a copy of the event
    ##  returns false if the event could not be pushed to the queue (out of memory?)
    try_push*: proc (list: ptr clap_output_events; event: ptr clap_event_header): bool {.
        cdecl.}

