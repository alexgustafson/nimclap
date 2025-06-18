# This is just an example to get you started. A typical library package
# exports the main API in this file. Note that you cannot rename this file
# but you can remove it if you wish.
import std/math
import nimclap/clap/version
import nimclap/clap/plugin
import nimclap/clap/pluginfeatures
import nimclap/clap/host
import nimclap/clap/id
import nimclap/clap/stringsizes
import nimclap/clap/stream
import nimclap/clap/events
import nimclap/clap/process
import nimclap/clap/entry
import nimclap/clap/audiobuffer


import nimclap/clap/factory/pluginfactory

import nimclap/clap/ext/log
import nimclap/clap/ext/state
import nimclap/clap/ext/threadcheck
import nimclap/clap/ext/audioports
import nimclap/clap/ext/noteports
import nimclap/clap/ext/latency


export version
export plugin
export pluginfeatures
export host
export id
export stringsizes
export stream
export events
export process
export entry

export pluginfactory

export latency
export log
export state
export threadcheck
export audioports
export noteports
export latency

const
  uint32Max* = uint32.high
  UINT32_MAX* = uint32.high


type

    ClapEventTypes* {.pure.} = enum
        noteOn = 0,
        noteOff = 1,
        noteChoke = 2,
        noteEnd = 3,
        noteExpression = 4,
        paramValue = 5,
        paramMod = 6,
        paramGestureBegin = 7,
        paramGestureEnd = 8,
        transport = 9,
        midi = 10,
        midiSysex = 11,
        midi2 = 12,

    ClapPluginDescriptor* = clap_plugin_descriptor
    ClapPlugin* = clap_plugin
    ClapHost* = clap_host
    ClapHostLatency* = clap_host_latency
    ClapPluginAudioPorts* = clap_plugin_audio_ports
    ClapAudioPortInfo* = clap_audio_port_info
    ClapNotePortInfo* = clap_note_port_info
    ClapPluginNotePorts* = clap_plugin_note_ports
    ClapPluginLatency* = clap_plugin_latency
    ClapOstream* = clap_ostream
    ClapIstream* = clap_istream
    ClapPluginState* = clap_plugin_state
    ClapHostLog* = clap_host_log
    ClapHostThreadCheck* = clap_host_thread_check
    ClapHostState* = clap_host_state
    ClapEventHeader* = clap_event_header
    ClapEventNote* = clap_event_note
    ClapEventNoteExpression* = clap_event_note_expression
    ClapEventParamValue* = clap_event_param_value
    ClapEventParamMod* = clap_event_param_mod
    ClapEventTranport* = clap_event_transport
    ClapEventMidi* = clap_event_midi
    ClapEventMidiSysex* = clap_event_midi_sysex
    ClapEventMidi2* = clap_event_midi2
    ClapProcessStatus* = clap_process_status
    ClapProcess* = clap_process
    ClapPluginFactory* = clap_plugin_factory
    ClapPluginEntry* = clap_plugin_entry
    ClapInputEvents* = clap_input_events
    ClapOutputEvents* = clap_output_events
    ClapAudioBuffer* = clap_audio_buffer



    uint8T*  = uint8
    uint16T* = uint16
    uint32T* = uint32
    uint64T* = uint64
    int8T*   = int8
    int16T*  = int16
    int32T*  = int32
    int64T*  = int64


proc setName*(dest: var array[CLAP_NAME_SIZE, char], src: string) =
  let maxLen = min(src.len, CLAP_NAME_SIZE - 1)
  for i in 0..<maxLen:
    dest[i] = src[i]
  dest[maxLen] = '\0'

# Helper for safely getting event count from input events
proc getEventCount*(events: ptr ClapInputEvents): uint32 =
  if events.isNil: 0'u32 else: events.size(events)

# Helper for safely getting an event from input events
proc getEvent*(events: ptr ClapInputEvents, index: uint32): ptr ClapEventHeader =
  if events.isNil: nil else: events.get(events, index)

# Helper for safely pushing to output events
proc tryPushEvent*(events: ptr ClapOutputEvents, event: ptr ClapEventHeader): bool =
  if events.isNil: false else: events.tryPush(events, event)

# Helper for safely accessing audio buffer data
proc getChannelData32*(buffer: ptr ClapAudioBuffer, channel: uint32): ptr UncheckedArray[cfloat] =
  if buffer.isNil or buffer.data32.isNil or channel >= buffer.channelCount:
    nil
  else:
    buffer.data32[channel]


# Template for safe pointer field access
template safeAccess*[T](p: ptr T, field: untyped, default: untyped): untyped =
  if p.isNil: default else: p.field


proc keyNumberToFrequency*(keyNumber: int): float =
  const A440 = 440.0
  return A440 * pow(2.0, (keyNumber.float - 69) / 12.0)

proc phaseIncrementForFrequency*(frequency: float, sampleRate: float): float =
  return

