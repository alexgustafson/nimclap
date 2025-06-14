## This file demonstrates how to wire a CLAP plugin in Nim
## You can use it as a starting point for your own plugins
## This is a translation of the C plugin-template.c from the CLAP project

import ../src/nimclap
import std/strformat

# Plugin descriptor
let myPlugDesc* {.exportc: "s_my_plug_desc".} = ClapPluginDescriptor(
  clap_version: CLAP_VERSION_INIT,
  id: "com.your-company.YourPlugin".cstring,
  name: "Plugin Name".cstring,
  vendor: "Vendor".cstring,
  url: "https://your-domain.com/your-plugin".cstring,
  manual_url: "https://your-domain.com/your-plugin/manual".cstring,
  support_url: "https://your-domain.com/support".cstring,
  version: "1.4.2".cstring,
  description: "The plugin description.".cstring,
  features: cast[ptr UncheckedArray[cstring]](allocShared0(3 * sizeof(cstring)))
)

# Initialize features array
block:
  let features = cast[ptr UncheckedArray[cstring]](myPlugDesc.features)
  features[0] = CLAP_PLUGIN_FEATURE_INSTRUMENT
  features[1] = CLAP_PLUGIN_FEATURE_STEREO
  features[2] = nil

# Plugin instance type
type
  MyPlug* = object
    plugin*: ClapPlugin
    host*: ptr ClapHost
    hostLatency*: ptr ClapHostLatency
    hostLog*: ptr ClapHostLog
    hostThreadCheck*: ptr ClapHostThreadCheck
    hostState*: ptr ClapHostState
    latency*: uint32

#############################
# clap_plugin_audio_ports
#############################

proc myPlugAudioPortsCount(plugin: ptr ClapPlugin, isInput: bool): uint32 {.cdecl.} =
  # We just declare 1 audio input and 1 audio output
  return 1

proc myPlugAudioPortsGet(plugin: ptr ClapPlugin, index: uint32, isInput: bool, 
                        info: ptr ClapAudioPortInfo): bool {.cdecl.} =
  if isInput or index >= 0:
    return false
  info.id = 0
  info.channelCount = 2
  info.flags = CLAP_AUDIO_PORT_IS_MAIN
  info.portType = CLAP_PORT_STEREO
  info.inPlacePair = CLAP_INVALID_ID
  info.name = cast[array[CLAP_NAME_SIZE, char]]("Audio Output")
  return true

let myPlugAudioPorts* {.exportc: "s_my_plug_audio_ports".} = ClapPluginAudioPorts(
  count: myPlugAudioPortsCount,
  get: myPlugAudioPortsGet
)

############################
# clap_plugin_note_ports
############################

proc myPlugNotePortsCount(plugin: ptr ClapPlugin, isInput: bool): uint32 {.cdecl.} =
  # We just declare 1 note input
  if isInput:
    return 1
  else:
    return 0

proc myPlugNotePortsGet(plugin: ptr ClapPlugin, index: uint32, isInput: bool,
                       info: ptr ClapNotePortInfo): bool {.cdecl.} =
  if index > 0 or not isInput:
    return false
  
  info.id = 0
  info.name = cast[array[CLAP_NAME_SIZE, char]]("Note Port")
  info.supported_dialects = CLAP_NOTE_DIALECT_CLAP or CLAP_NOTE_DIALECT_MIDI_MPE or CLAP_NOTE_DIALECT_MIDI2
  info.preferred_dialect = CLAP_NOTE_DIALECT_CLAP
  return true

let myPlugNotePorts* {.exportc: "s_my_plug_note_ports".} = ClapPluginNotePorts(
  count: myPlugNotePortsCount,
  get: myPlugNotePortsGet
)

####################
# clap_latency
####################

proc myPlugLatencyGet(plugin: ptr ClapPlugin): uint32 {.cdecl.} =
  let plug = cast[ptr MyPlug](plugin.plugin_data)
  return plug.latency

let myPlugLatency* {.exportc: "s_my_plug_latency".} = ClapPluginLatency(
  get: myPlugLatencyGet
)

##################
# clap_state
##################

proc myPlugStateSave(plugin: ptr ClapPlugin, stream: ptr ClapOstream): bool {.cdecl.} =
  let plug = cast[ptr MyPlug](plugin.plugin_data)
  # TODO: write the state into stream
  return true

proc myPlugStateLoad(plugin: ptr ClapPlugin, stream: ptr ClapIstream): bool {.cdecl.} =
  let plug = cast[ptr MyPlug](plugin.plugin_data)
  # TODO: read the state from stream
  return true

let myPlugState* {.exportc: "s_my_plug_state".} = ClapPluginState(
  save: myPlugStateSave,
  load: myPlugStateLoad
)

###################
# clap_plugin
###################

proc myPlugInit(plugin: ptr ClapPlugin): bool {.cdecl.} =
  let plug = cast[ptr MyPlug](plugin.plugin_data)
  
  # Fetch host's extensions here
  # Make sure to check that the interface functions are not null pointers
  plug.hostLog = cast[ptr ClapHostLog](plug.host.get_extension(plug.host, CLAP_EXT_LOG))
  plug.hostThreadCheck = cast[ptr ClapHostThreadCheck](plug.host.get_extension(plug.host, CLAP_EXT_THREAD_CHECK))
  plug.hostLatency = cast[ptr ClapHostLatency](plug.host.get_extension(plug.host, CLAP_EXT_LATENCY))
  plug.hostState = cast[ptr ClapHostState](plug.host.get_extension(plug.host, CLAP_EXT_STATE))
  return true

proc myPlugDestroy(plugin: ptr ClapPlugin) {.cdecl.} =
  let plug = cast[ptr MyPlug](plugin.plugin_data)
  dealloc(plug)

proc myPlugActivate(plugin: ptr ClapPlugin, sampleRate: float64, 
                   minFramesCount: uint32, maxFramesCount: uint32): bool {.cdecl.} =
  return true

proc myPlugDeactivate(plugin: ptr ClapPlugin) {.cdecl.} =
  discard

proc myPlugStartProcessing(plugin: ptr ClapPlugin): bool {.cdecl.} =
  return true

proc myPlugStopProcessing(plugin: ptr ClapPlugin) {.cdecl.} =
  discard

proc myPlugReset(plugin: ptr ClapPlugin) {.cdecl.} =
  discard

proc myPlugProcessEvent(plug: ptr MyPlug, hdr: ptr ClapEventHeader) =
  if hdr.space_id == CLAP_CORE_EVENT_SPACE_ID:
    case cast[ClapEventTypes](hdr.type)
    of ClapEventTypes.noteOn:
      let ev = cast[ptr ClapEventNote](hdr)
      # TODO: handle note on
      discard
    
    of ClapEventTypes.noteOff:
      let ev = cast[ptr ClapEventNote](hdr)
      # TODO: handle note off
      discard
    
    of ClapEventTypes.noteChoke:
      let ev = cast[ptr ClapEventNote](hdr)
      # TODO: handle note choke
      discard
    
    of ClapEventTypes.noteExpression:
      let ev = cast[ptr ClapEventNoteExpression](hdr)
      # TODO: handle note expression
      discard
    
    of ClapEventTypes.paramValue:
      let ev = cast[ptr ClapEventParamValue](hdr)
      # TODO: handle parameter change
      discard
    
    of ClapEventTypes.paramMod:
      let ev = cast[ptr ClapEventParamMod](hdr)
      # TODO: handle parameter modulation
      discard
    
    of ClapEventTypes.transport:
      let ev = cast[ptr ClapEventTranport](hdr)
      # TODO: handle transport event
      discard
    
    of ClapEventTypes.midi:
      let ev = cast[ptr ClapEventMidi](hdr)
      # TODO: handle MIDI event
      discard
    
    of ClapEventTypes.midiSysex:
      let ev = cast[ptr ClapEventMidiSysex](hdr)
      # TODO: handle MIDI Sysex event
      discard
    
    of ClapEventTypes.midi2:
      let ev = cast[ptr ClapEventMidi2](hdr)
      # TODO: handle MIDI2 event
      discard
    
    else:
      discard

proc myPlugProcess(plugin: ptr ClapPlugin, process: ptr ClapProcess): ClapProcessStatus {.cdecl.} =
  let plug = cast[ptr MyPlug](plugin.plugin_data)
  let nframes = process.frames_count
  let nev = process.in_events.size(process.in_events)
  var evIndex: uint32 = 0
  var nextEvFrame = if nev > 0: 0'u32 else: nframes
  
  var i: uint32 = 0
  while i < nframes:
    # Handle every event that happens at the frame "i"
    while evIndex < nev and nextEvFrame == i:
      let hdr = process.in_events.get(process.in_events, evIndex)
      if hdr.time != i:
        nextEvFrame = hdr.time
        break
      
      myPlugProcessEvent(plug, hdr)
      inc(evIndex)
      
      if evIndex == nev:
        # We reached the end of the event list
        nextEvFrame = nframes
        break
    
    # Process every sample until the next event
    while i < nextEvFrame:
      # Fetch input samples
      let inL = process.audio_inputs[0].data32[0][i]
      let inR = process.audio_inputs[0].data32[1][i]
      
      # TODO: process samples, here we simply swap left and right channels
      let outL = inR
      let outR = inL
      
      # Store output samples
      process.audio_outputs[0].data32[0][i] = outL
      process.audio_outputs[0].data32[1][i] = outR
      
      inc(i)
  
  return CLAP_PROCESS_CONTINUE

proc myPlugGetExtension(plugin: ptr ClapPlugin, id: cstring): pointer {.cdecl.} =
  if id == CLAP_EXT_LATENCY:
    return addr myPlugLatency
  if id == CLAP_EXT_AUDIO_PORTS:
    return addr myPlugAudioPorts
  if id == CLAP_EXT_NOTE_PORTS:
    return addr myPlugNotePorts
  if id == CLAP_EXT_STATE:
    return addr myPlugState
  # TODO: add support to CLAP_EXT_PARAMS
  return nil

proc myPlugOnMainThread(plugin: ptr ClapPlugin) {.cdecl.} =
  discard

proc myPlugCreate*(host: ptr ClapHost): ptr ClapPlugin {.cdecl.} =
  var p = cast[ptr MyPlug](allocShared0(sizeof(MyPlug)))
  p.host = host
  p.plugin.desc = addr myPlugDesc
  p.plugin.plugin_data = p
  p.plugin.init = myPlugInit
  p.plugin.destroy = myPlugDestroy
  p.plugin.activate = myPlugActivate
  p.plugin.deactivate = myPlugDeactivate
  p.plugin.start_processing = myPlugStartProcessing
  p.plugin.stop_processing = myPlugStopProcessing
  p.plugin.reset = myPlugReset
  p.plugin.process = myPlugProcess
  p.plugin.get_extension = myPlugGetExtension
  p.plugin.on_main_thread = myPlugOnMainThread
  
  # Don't call into the host here
  
  return addr p.plugin

#########################
# clap_plugin_factory
#########################

type
  PluginEntry = object
    desc: ptr ClapPluginDescriptor
    create: proc(host: ptr ClapHost): ptr ClapPlugin {.cdecl.}

var plugins = [
  PluginEntry(
    desc: addr myPlugDesc,
    create: myPlugCreate
  )
]

proc pluginFactoryGetPluginCount(factory: ptr ClapPluginFactory): uint32 {.cdecl.} =
  return uint32(plugins.len)

proc pluginFactoryGetPluginDescriptor(factory: ptr ClapPluginFactory, index: uint32): ptr ClapPluginDescriptor {.cdecl.} =
  if index < uint32(plugins.len):
    return plugins[index].desc
  return nil

proc pluginFactoryCreatePlugin(factory: ptr ClapPluginFactory, host: ptr ClapHost, 
                              pluginId: cstring): ptr ClapPlugin {.cdecl.} =
  if not clap_version_is_compatible(host.clap_version):
    return nil
  
  for i in 0..<plugins.len:
    if pluginId == plugins[i].desc.id:
      return plugins[i].create(host)
  
  return nil

let pluginFactory* {.exportc: "s_plugin_factory".} = ClapPluginFactory(
  get_plugin_count: pluginFactoryGetPluginCount,
  get_plugin_descriptor: pluginFactoryGetPluginDescriptor,
  create_plugin: pluginFactoryCreatePlugin
)

##################
# clap_entry
##################

var gEntryInitCounter = 0

proc entryInit(pluginPath: cstring): bool =
  # Perform the plugin initialization
  return true

proc entryDeinit() =
  # Perform the plugin de-initialization
  discard

# Thread safe init counter
proc entryInitGuard(pluginPath: cstring): bool {.cdecl.} =
  # Note: Thread safety implementation omitted for simplicity
  # In production, you would need proper mutex/lock implementation
  
  inc(gEntryInitCounter)
  assert(gEntryInitCounter > 0)
  
  var succeed = true
  if gEntryInitCounter == 1:
    succeed = entryInit(pluginPath)
    if not succeed:
      gEntryInitCounter = 0
  
  return succeed

# Thread safe deinit counter
proc entryDeinitGuard() {.cdecl.} =
  # Note: Thread safety implementation omitted for simplicity
  
  dec(gEntryInitCounter)
  assert(gEntryInitCounter >= 0)
  
  if gEntryInitCounter == 0:
    entryDeinit()

proc entryGetFactory(factoryId: cstring): pointer {.cdecl.} =
  assert(gEntryInitCounter > 0)
  if gEntryInitCounter <= 0:
    return nil
  
  if factoryId == CLAP_PLUGIN_FACTORY_ID:
    return addr pluginFactory
  return nil

# This symbol will be resolved by the host
var clap_entry* {.exportc, dynlib.}: ClapPluginEntry = ClapPluginEntry(
  clap_version: CLAP_VERSION_INIT,
  init: entryInitGuard,
  deinit: entryDeinitGuard,
  get_factory: entryGetFactory
)