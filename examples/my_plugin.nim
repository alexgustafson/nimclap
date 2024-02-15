import std/cstrutils
import ../src/nimclap


let myPluginDescriptor {.exportc.}: ClapPluginDescriptor = ClapPluginDescriptor(
    clapVersion: CLAP_VERSION,
    id: "com.example.my-plugin".cstring,
    name: "My Plugin".cstring,
    vendor: "My Company".cstring,
    url: "https://your-domain.com/my-plugin".cstring,
    manualUrl: "https://your-domain.com/my-plugin/manual".cstring,
    support_url: "https://your-domain.com/support".cstring,
    version: "1.4.2".cstring,
    description: "The plugin description.".cstring,
    features: allocCStringArray([
      CLAP_PLUGIN_FEATURE_AUDIO_EFFECT,
      CLAP_PLUGIN_FEATURE_MIXING,
      CLAP_PLUGIN_FEATURE_STEREO,
    ])
)

type MyPluginData = object 
    plugin*: ClapPlugin
    host*: ptr ClapHost
    host_latency*: ptr ClapHostLatency
    host_log*: ptr clapHostLog
    host_thread_check*: ptr clapHostThreadCheck
    host_state*: ptr clapHostState
    latency: uint32
    sampleRate: cdouble



#############################
## clap_plugin_audio_ports ##
#############################

proc myPluginAudioPortsCount(plugin: ptr ClapPlugin, isInput: bool): uint32  {.cdecl.} =
    result = 1

proc myPluginAudioPortsGet*(plugin: ptr ClapPlugin;
                            index: uint32;
                            is_input: bool; 
                            info: ptr clap_audio_port_info): bool {.cdecl.} =
  if index > 0:
    return false
  info.id = 0
  info.name = cast[array[CLAP_NAME_SIZE, char]]("My Port Name")
  info.channel_count = 2
  info.flags = CLAP_AUDIO_PORT_IS_MAIN
  info.port_type = CLAP_PORT_STEREO
  info.in_place_pair = CLAP_INVALID_ID
  return true

let myPluginAudioPorts: ClapPluginAudioPorts = ClapPluginAudioPorts(
    count: myPluginAudioPortsCount,
    get: myPluginAudioPortsGet,
)

############################
## clap_plugin_note_ports ##
############################

proc myPluginNotePortsCount(plugin: ptr ClapPlugin, isInput: bool): uint32  {.cdecl.} =
    result = 1

proc myPluginNotePortsGet(plugin: ptr ClapPlugin;
                           index: uint32;
                           is_input: bool; 
                           info: ptr ClapNotePortInfo): bool {.cdecl.} =
  if index > 0:
    return false
  info.id = 0
  info.name = cast[array[CLAP_NAME_SIZE, char]]("My Port Name")
  info.supportedDialects = ord(CLAP_NOTE_DIALECT_CLAP) or
                           ord(CLAP_NOTE_DIALECT_MIDI) or
                           ord(CLAP_NOTE_DIALECT_MIDI2)
  info.preferredDialect = ord(CLAP_NOTE_DIALECT_CLAP)
  return true

let myPluginNotePorts: ClapPluginNotePorts = ClapPluginNotePorts(
    count: myPluginNotePortsCount,
    get: myPluginNotePortsGet,
)

##################
## clap_latency ##
##################

proc myPluginLatencyGet(plugin: ptr ClapPlugin): uint32 {.cdecl.} =
  var pluginData: ptr MyPluginData = cast[ptr MyPluginData](plugin.plugin_data)
  result = pluginData.latency

let myPluginLatency: ClapPluginLatency = ClapPluginLatency(
    get: myPluginLatencyGet,
)

################
## clap_state ##
################

proc myPluginStateSave(plugin: ptr ClapPlugin;
                       stream: ptr ClapOstream): bool {.cdecl.} =
  var pluginData: ptr MyPluginData = cast[ptr MyPluginData](plugin.plugin_data)
  # TODO: write the state into stream
  return true

proc myPluginStateLoad(plugin: ptr ClapPlugin;
                       stream: ptr ClapIstream): bool {.cdecl.} =
  var pluginData: ptr MyPluginData = cast[ptr MyPluginData](plugin.plugin_data)
  # TODO: read the state from stream
  return true

let myPluginState: ClapPluginState = ClapPluginState(
    save: myPluginStateSave,
    load: myPluginStateLoad,
)

#################
## clap_plugin ##
#################

proc myPluginInit(plugin: ptr ClapPlugin): bool {.cdecl.} =
  var pluginData: ptr MyPluginData = cast[ptr MyPluginData](plugin.plugin_data)
  
  # pluginData.host_log = cast[ptr ClapHostLog](pluginData.host.get_extension(pluginData.host, CLAP_EXT_LOG))
  # pluginData.host_thread_check = cast[ptr ClapHostThreadCheck](pluginData.host.get_extension(pluginData.host, CLAP_EXT_THREAD_CHECK))
  # pluginData.host_state = cast[ptr ClapHostState](pluginData.host.get_extension(pluginData.host, CLAP_EXT_STATE))
  # pluginData.host_latency = cast[ptr ClapHostLatency](pluginData.host.get_extension(pluginData.host, CLAP_EXT_LATENCY))  
  return true

proc myPluginDestroy(plugin: ptr ClapPlugin) {.cdecl.} =
  var pluginData: ptr MyPluginData = cast[ptr MyPluginData](plugin.plugin_data)
  dealloc pluginData

proc myPluginActivate(plugin: ptr ClapPlugin, sampleRate: cdouble, minFramesCount: uint32, maxFramesCount: uint32): bool {.cdecl.} =
  var pluginData: ptr MyPluginData = cast[ptr MyPluginData](plugin.plugin_data)
  # pluginData.sampleRate = sampleRate
  return true

proc myPluginDeactivate(plugin: ptr ClapPlugin) {.cdecl.} =
  discard

proc myPluginStartProcessing(plugin: ptr ClapPlugin): bool {.cdecl.} =
  return true

proc myPluginStopProcessing(plugin: ptr ClapPlugin) {.cdecl.} =
  discard

proc myPluginReset(plugin: ptr ClapPlugin) {.cdecl.} =
  discard

proc myPluginProcessEvent(pluginData: ptr MyPluginData; hdr: ptr ClapEventHeader) {.cdecl.} =
  if hdr.spaceId == CLAP_CORE_EVENT_SPACE_ID:
    case hdr.`type`:
      of ord(ClapEventTypes.noteOn):
        let ev: ptr ClapEventNote = cast[ptr ClapEventNote](hdr)
        ##  TODO: handle note on
      of ord(ClapEventTypes.noteOff):
        let ev: ptr ClapEventNote = cast[ptr ClapEventNote](hdr)
        ## TODO: handle note off event
      of ord(ClapEventTypes.noteChoke):
        let ev: ptr ClapEventNote = cast[ptr ClapEventNote](hdr)
        ## TODO: handle note choke event
      of ord(ClapEventTypes.noteEnd):
        let ev: ptr ClapEventNote = cast[ptr ClapEventNote](hdr)
        ## TODO: handle note end event
      of ord(ClapEventTypes.noteExpression):
        let ev: ptr ClapEventNoteExpression = cast[ptr ClapEventNoteExpression](hdr)
        ## TODO: handle note expression event
      of ord(ClapEventTypes.paramValue):
        let ev: ptr ClapEventParamValue = cast[ptr ClapEventParamValue](hdr)
        ## TODO: handle param value event
      of ord(ClapEventTypes.paramMod):
        let ev: ptr clap_event_param_mod = cast[ptr clap_event_param_mod](hdr)
        ## TODO: handle param mod event
      of ord(ClapEventTypes.midi):
        let ev: ptr clap_event_midi = cast[ptr clap_event_midi](hdr)
        ## TODO: handle midi event
      of ord(ClapEventTypes.midi2):
        let ev: ptr clap_event_midi2 = cast[ptr clap_event_midi2](hdr)
      of ord(ClapEventTypes.midiSysex):
        let ev: ptr clap_event_midi_sysex = cast[ptr clap_event_midi_sysex](hdr)
      else:
        discard

proc myPluginProcess(plugin: ptr ClapPlugin; process: ptr ClapProcess): ClapProcessStatus {.cdecl.} =
  var pluginData: ptr MyPluginData = cast[ptr MyPluginData](plugin.plugin_data)

  let nframes: uint32 = process.frames_count
  let nev: uint32 = process.in_events.size(process.in_events)
  var ev_index: uint32 = 0
  var next_ev_frame: uint32 = if nev > 0: 0 else: nframes
  var i: uint32 = 0
  while i < nframes:
    ##  handle every events that happrens at the frame "i"
    while ev_index < nev and next_ev_frame == i:
      let hdr: ptr ClapEventHeader = process.in_events.get(process.in_events, ev_index)
      if hdr.time != i:
        next_ev_frame = hdr.time
        break
      myPluginProcessEvent(pluginData, hdr)
      inc(ev_index)
      if ev_index == nev:
        ##  we reached the end of the event list
        next_ev_frame = nframes
        break
    ##  process every samples until the next event
    while i < next_ev_frame:
      ##  fetch input samples
      let in_l: cfloat = process.audio_inputs[0].data32[0][i]
      let in_r: cfloat = process.audio_inputs[0].data32[1][i]
      ##  TODO: process samples, here we simply swap left and right channels
      let out_l: cfloat = in_r
      let out_r: cfloat = in_l
      ##  store output samples
      process.audio_outputs[0].data32[0][i] = out_l
      process.audio_outputs[0].data32[1][i] = out_r
      inc(i)
  return CLAP_PROCESS_CONTINUE

proc myPluginGetExtension(plugin: ptr ClapPlugin; id: cstring): pointer {.cdecl.} =
  if 0 == cmpIgnoreCase(id, CLAP_EXT_LATENCY):
    return cast[pointer](addr(myPluginLatency))
  if 0 == cmpIgnoreCase(id, CLAP_EXT_AUDIO_PORTS):
    return cast[pointer](addr(myPluginAudioPorts))
  if 0 == cmpIgnoreCase(id, CLAP_EXT_NOTE_PORTS):
    return cast[pointer](addr(myPluginNotePorts))
  if 0 == cmpIgnoreCase(id, CLAP_EXT_STATE):
    return cast[pointer](addr(myPluginState))
  # TODO: add support to CLAP_EXT_PARAMS
  return nil

proc myPluginOnMainThread(plugin: ptr ClapPlugin) {.cdecl.} =
  discard

proc myPluginCreate(host: ptr ClapHost): ptr ClapPlugin =

  let pluginData = cast[ptr MyPluginData](allocShared0(sizeof(MyPluginData)))

  pluginData.host = host
  pluginData.latency = 0
  pluginData.sampleRate = 0

  let pluginRef: ClapPluginRef = ClapPluginRef(
      desc: addr(myPluginDescriptor),
      plugin_data: pluginData,
      init: myPluginInit,
      destroy: myPluginDestroy,
      activate: myPluginActivate,
      deactivate: myPluginDeactivate,
      start_processing: myPluginStartProcessing,
      stop_processing: myPluginStopProcessing,
      reset: myPluginReset,
      process: myPluginProcess,
      get_extension: myPluginGetExtension,
      on_main_thread: myPluginOnMainThread,
  )

  pluginData.plugin = cast[ClapPlugin](pluginRef)

  GC_ref(pluginRef)
  return cast[ptr ClapPlugin](pluginRef)


#########################
## clap_plugin_factory ##
#########################

type PluginEntry = object
    desc: ptr ClapPluginDescriptor
    create: proc (host: ptr ClapHost): ptr ClapPlugin

var plugins: seq[PluginEntry] = newSeq[PluginEntry]()

plugins.add(
    PluginEntry(
        desc: addr myPluginDescriptor,
        create: myPluginCreate,
    )
)

proc myPluginFactoryGetCount(factory: ptr ClapPluginFactory): uint32 {.cdecl.} =
  result = cast[uint32](plugins.len)

proc myPluginFactoryGetDescriptor(factory: ptr ClapPluginFactory, index: uint32): ptr ClapPluginDescriptor {.cdecl.} =
  result = plugins[index].desc

proc myPluginFactoryCreatePlugin(factory: ptr ClapPluginFactory,
                                  host: ptr ClapHost,
                                  pluginId: cstring): ptr ClapPlugin {.cdecl.} =
  if not clapVersionIsCompatible(host.clap_version):
    return nil

  for entry in plugins:
    if 0 == cmpIgnoreCase(entry.desc.id, pluginId):
      return entry.create(host)

  return nil


let clapPluginFactory {.exportc.}: ClapPluginFactory = ClapPluginFactory(
    get_plugin_count: myPluginFactoryGetCount,
    get_plugin_descriptor: myPluginFactoryGetDescriptor,
    create_plugin: myPluginFactoryCreatePlugin,
)


################
## clap_entry ##
################

proc entryInit(pluginPath: cstring): bool {.cdecl.} =
  return true

proc entryDeinit() {.cdecl.} =
  discard

proc entryGetFactory(factoryId: cstring): pointer {.cdecl.} =
  if factoryId == CLAP_PLUGIN_FACTORY_ID:
    return cast[pointer](addr(clapPluginFactory))
  return nil

var clap_entry* {.exportc, dynlib.} : ClapPluginEntry = ClapPluginEntry(
    clap_version: CLAP_VERSION,
    init: entryInit,
    deinit: entryDeinit,
    get_factory: entryGetFactory,
)