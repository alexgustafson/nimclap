## This file demonstrates how to wire a CLAP plugin in Nim
## You can use it as a starting point for your own plugins
## This is a translation of the C plugin-template.c from the CLAP project

import ../src/nimclap
import std/strformat

# Plugin descriptor
let myPlugDesc* {.exportc: "s_my_plug_desc".} = PluginDescriptor(
  clapVersion: versionInit,
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
  features[0] = pluginFeatureInstrument
  features[1] = pluginFeatureStereo
  features[2] = nil

# Plugin instance type
type
  MyPlug* = object
    plugin*: Plugin
    host*: ptr Host
    hostLatency*: ptr HostLatency
    hostLog*: ptr HostLog
    hostThreadCheck*: ptr HostThreadCheck
    hostState*: ptr HostState
    latency*: uint32

#############################
# clap_plugin_audio_ports
#############################

proc myPlugAudioPortsCount(plugin: ptr Plugin, isInput: bool): uint32 {.cdecl.} =
  # We just declare 1 audio input and 1 audio output
  return 1

proc myPlugAudioPortsGet(plugin: ptr Plugin, index: uint32, isInput: bool,
                        info: ptr AudioPortInfo): bool {.cdecl.} =
  if isInput or index >= 0:
    return false
  info.id = 0
  info.channelCount = 2
  info.flags = audioPortIsMain
  info.portType = portStereo
  info.inPlacePair = invalidId
  info.name = cast[array[nameSize, char]]("Audio Output")
  return true

let myPlugAudioPorts* {.exportc: "s_my_plug_audio_ports".} = PluginAudioPorts(
  count: myPlugAudioPortsCount,
  get: myPlugAudioPortsGet
)

############################
# clap_plugin_note_ports
############################

proc myPlugNotePortsCount(plugin: ptr Plugin, isInput: bool): uint32 {.cdecl.} =
  # We just declare 1 note input
  if isInput:
    return 1
  else:
    return 0

proc myPlugNotePortsGet(plugin: ptr Plugin, index: uint32, isInput: bool,
                       info: ptr NotePortInfo): bool {.cdecl.} =
  if index > 0 or not isInput:
    return false
  
  info.id = 0
  info.name = cast[array[nameSize, char]]("Note Port")
  info.supported_dialects = NoteDialect.dialectClap.ord or NoteDialect.dialectMidiMpe.ord or NoteDialect.dialectMidi2.ord
  info.preferred_dialect = NoteDialect.dialectClap.ord
  return true

let myPlugNotePorts* = PluginNotePorts(
  count: myPlugNotePortsCount,
  get: myPlugNotePortsGet
)

####################
# clap_latency
####################

proc myPlugLatencyGet(plugin: ptr Plugin): uint32 {.cdecl.} =
  let plug = cast[ptr MyPlug](plugin.plugin_data)
  return plug.latency

let myPlugLatency*  = PluginLatency(
  get: myPlugLatencyGet
)

##################
# clap_state
##################

proc myPlugStateSave(plugin: ptr Plugin, stream: ptr Ostream): bool {.cdecl.} =
  let plug = cast[ptr MyPlug](plugin.plugin_data)
  # TODO: write the state into stream
  return true

proc myPlugStateLoad(plugin: ptr Plugin, stream: ptr Istream): bool {.cdecl.} =
  let plug = cast[ptr MyPlug](plugin.plugin_data)
  # TODO: read the state from stream
  return true

let myPlugState* = PluginState(
  save: myPlugStateSave,
  load: myPlugStateLoad
)

###################
# clap_plugin
###################

proc myPlugInit(plugin: ptr Plugin): bool {.cdecl.} =
  let plug = cast[ptr MyPlug](plugin.plugin_data)
  
  # Fetch host's extensions here
  # Make sure to check that the interface functions are not null pointers
  plug.hostLog = cast[ptr HostLog](plug.host.get_extension(plug.host, extLog))
  plug.hostThreadCheck = cast[ptr HostThreadCheck](plug.host.get_extension(plug.host, extThreadCheck))
  plug.hostLatency = cast[ptr HostLatency](plug.host.get_extension(plug.host, extLatency))
  plug.hostState = cast[ptr HostState](plug.host.get_extension(plug.host, extState))
  return true

proc myPlugDestroy(plugin: ptr Plugin) {.cdecl.} =
  let plug = cast[ptr MyPlug](plugin.plugin_data)
  dealloc(plug)

proc myPlugActivate(plugin: ptr Plugin, sampleRate: float64,
                   minFramesCount: uint32, maxFramesCount: uint32): bool {.cdecl.} =
  return true

proc myPlugDeactivate(plugin: ptr Plugin) {.cdecl.} =
  discard

proc myPlugStartProcessing(plugin: ptr Plugin): bool {.cdecl.} =
  return true

proc myPlugStopProcessing(plugin: ptr Plugin) {.cdecl.} =
  discard

proc myPlugReset(plugin: ptr Plugin) {.cdecl.} =
  discard

proc myPlugProcessEvent(plug: ptr MyPlug, hdr: ptr EventHeader) =
  if hdr.space_id == coreEventSpaceId:
    case hdr.type
    of eventNoteOn:
      let ev = cast[ptr EventNote](hdr)
      # TODO: handle note on
      discard
    
    of eventNoteOff:
      let ev = cast[ptr EventNote](hdr)
      # TODO: handle note off
      discard
    
    of eventNoteChoke:
      let ev = cast[ptr EventNote](hdr)
      # TODO: handle note choke
      discard
    
    of eventNoteExpression:
      let ev = cast[ptr EventNoteExpression](hdr)
      # TODO: handle note expression
      discard
    
    of eventParamValue:
      let ev = cast[ptr EventParamValue](hdr)
      # TODO: handle parameter change
      discard
    
    of eventParamMod:
      let ev = cast[ptr EventParamMod](hdr)
      # TODO: handle parameter modulation
      discard
    
    of eventTransport:
      let ev = cast[ptr EventTransport](hdr)
      # TODO: handle transport event
      discard
    
    of eventMidi:
      let ev = cast[ptr EventMidi](hdr)
      # TODO: handle MIDI event
      discard
    
    of eventMidiSysex:
      let ev = cast[ptr EventMidiSysex](hdr)
      # TODO: handle MIDI Sysex event
      discard
    
    of eventMidi2:
      let ev = cast[ptr EventMidi2](hdr)
      # TODO: handle MIDI2 event
      discard
    
    else:
      discard

proc myPlugProcess(plugin: ptr Plugin, process: ptr Process): ProcessStatus {.cdecl.} =
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
  
  return processContinue

proc myPlugGetExtension(plugin: ptr Plugin, id: cstring): pointer {.cdecl.} =
  if id == extLatency:
    return addr myPlugLatency
  if id == extAudioPorts:
    return addr myPlugAudioPorts
  if id == extNotePorts:
    return addr myPlugNotePorts
  if id == extState:
    return addr myPlugState
  # TODO: add support to CLAP_EXT_PARAMS
  return nil

proc myPlugOnMainThread(plugin: ptr Plugin) {.cdecl.} =
  discard

proc myPlugCreate*(host: ptr Host): ptr Plugin {.cdecl.} =
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
  MyPluginEntry = object
    desc: ptr PluginDescriptor
    create: proc(host: ptr Host): ptr Plugin {.cdecl.}

var plugins = [
  MyPluginEntry(
    desc: addr myPlugDesc,
    create: myPlugCreate
  )
]

proc pluginFactoryGetPluginCount(factory: ptr PluginFactory): uint32 {.cdecl.} =
  return uint32(plugins.len)

proc pluginFactoryGetPluginDescriptor(factory: ptr PluginFactory, index: uint32): ptr PluginDescriptor {.cdecl.} =
  if index < uint32(plugins.len):
    return plugins[index].desc
  return nil

proc pluginFactoryCreatePlugin(factory: ptr PluginFactory, host: ptr Host,
                              pluginId: cstring): ptr Plugin {.cdecl.} =
  if not versionIsCompatible(host.clap_version):
    return nil
  
  for i in 0..<plugins.len:
    if pluginId == plugins[i].desc.id:
      return plugins[i].create(host)
  
  return nil

let pluginFactory*  = PluginFactory(
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
  
  if factoryId == pluginFactoryId:
    return addr pluginFactory
  return nil

# This symbol will be resolved by the host
var clap_entry* {.exportc, dynlib.}: PluginEntry = PluginEntry(
  clapVersion: versionInit,
  init: entryInitGuard,
  deinit: entryDeinitGuard,
  getFactory: entryGetFactory
)