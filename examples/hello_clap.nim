import ../src/nimclap
import std/math

type Voice = object
  held: bool
  noteId: int32
  channel: int16
  key: int16
  phase: float


type MyPlugin = object
  plugin: ClapPlugin
  host: ptr ClapHost
  sampleRate: float
  voices: seq[Voice]


let pluginDescriptor* {.exportc.}: ClapPluginDescriptor = ClapPluginDescriptor(
  clap_version: CLAP_VERSION_INIT,
  id: "nakst.HelloCLAP",
  name: "Hello CLAP",
  vendor: "nakst",
  url: "https://nakst.gitlab.io",
  manual_url: "",
  support_url: "",
  version: "1.0.0",
  description: "The best audio plugin ever.",
  features: allocCStringArray([
    CLAP_PLUGIN_FEATURE_AUDIO_EFFECT,
    CLAP_PLUGIN_FEATURE_MIXING,
    CLAP_PLUGIN_FEATURE_STEREO,
  ])
)

proc PluginProcessEvent(plugin: ptr MyPlugin, event: ptr ClapEventHeader) =
  if event.spaceId == CLAP_CORE_EVENT_SPACE_ID:
    if event.type == CLAP_EVENT_NOTE_ON or event.type == CLAP_EVENT_NOTE_OFF or event.type == CLAP_EVENT_NOTE_CHOKE:
      let noteEvent = cast[ptr ClapEventNote](event)

      for i in countdown(plugin.voices.len - 1, 0):
        var voice = plugin.voices[i]
        if (noteEvent.key == -1 or voice.key == noteEvent.key) and (noteEvent.noteId == -1 or voice.noteId == noteEvent.noteId) and (noteEvent.channel == -1 or voice.channel == noteEvent.channel):
          if event.type == CLAP_EVENT_NOTE_CHOKE:
            plugin.voices.del(i)
          else:
            voice.held = false

      if event.type == CLAP_EVENT_NOTE_ON:
        var voice = Voice(
          held: true,
          noteId: noteEvent.noteId,
          channel: noteEvent.channel,
          key: noteEvent.key,
          phase: 0.0,
        )
        plugin.voices.add(voice)

proc myPluginRenderAudio(plugin: ptr MyPlugin, startIndex: uint32, endIndex: uint32, outputL: ptr UncheckedArray[cfloat], outputR: ptr UncheckedArray[cfloat] ) =
  for index in startIndex..endIndex:
    var sum: float = 0.0
    for i in 0..plugin.voices.len:
      var voice = plugin.voices[i]
      if not voice.held:
        continue
      sum += sin(voice.phase * 2.0 * 3.14159) * 0.2

      let phase: float = 440.0 * pow(2.0, (cast[float](voice.key) - 57.0) / 12.0 ) / plugin.sampleRate

      voice.phase = phase
      voice.phase -= floor(voice.phase)

    outputL[index] = sum
    outputR[index] = sum




let extensionNotePorts = ClapPluginNotePorts(
  count: proc(plugin: ptr ClapPlugin, isInput: bool): uint32 {.cdecl.} =
    return if isInput : 1 else: 0,
  get: proc(plugin: ptr ClapPlugin, index: uint32, isInput: bool, info: ptr ClapNotePortInfo): bool {.cdecl} =
    if not isInput or index > 0:
       return false
    info.id = 0
    info.name.setName("Note Input Port")
    info.supportedDialects = ord(CLAP_NOTE_DIALECT_CLAP)
    info.preferredDialect = ord(CLAP_NOTE_DIALECT_CLAP)
    return true
)

let extensionAudioPorts = ClapPluginAudioPorts(
  count: proc(plugin: ptr ClapPlugin, isInput: bool): uint32 {.cdecl} =
    return if isInput : 0 else: 1,
  get: proc(plugin: ptr ClapPlugin, index: uint32, isInput: bool, info: ptr ClapAudioPortInfo): bool {.cdecl} =
    if isInput or index > 0:
      return false
    info.id = 0
    info.channelCount = 2
    info.flags = CLAP_AUDIO_PORT_IS_MAIN
    info.portType = CLAP_PORT_STEREO
    info.inPlacePair = CLAP_INVALID_ID
    info.name.setName("Audio Output Port")
    return true
)


let pluginClass: ClapPlugin = ClapPlugin(
  desc: pluginDescriptor.addr,
  plugin_data: nil,
  init: proc(plugin: ptr clap_plugin): bool {.cdecl.} =
    # var pluginData: ptr MyPlugin = cast[ptr MyPlugin](plugin.plugin_data)
    return true,
  destroy: proc(plugin: ptr ClapPlugin) {.cdecl.} =
    var pluginData: ptr MyPlugin = cast[ptr MyPlugin](plugin.plugin_data)
    deallocShared(pluginData),
  activate: proc(plugin: ptr ClapPlugin; sampleRate: float; minimumFramesCount: uint32; maximunFramesCount: uint32): bool {.cdecl.} =
    var pluginData: ptr MyPlugin = cast[ptr MyPlugin](plugin.plugin_data)
    pluginData.sampleRate = sampleRate
    return true,
  deactivate: proc(plugin: ptr ClapPlugin) {.cdecl.} =
    discard,
  start_processing: proc(plugin: ptr ClapPlugin): bool {.cdecl.} =
    return true,
  stop_processing: proc(plugin: ptr ClapPlugin) {.cdecl.} =
    discard,
  reset: proc(plugin: ptr ClapPlugin) {.cdecl.} =
    var pluginData: ptr MyPlugin = cast[ptr MyPlugin](plugin.plugin_data)
    pluginData.voices.setLen(0),
  process: proc (plugin: ptr ClapPlugin; process: ptr clap_process): ClapProcessStatus {.cdecl.} =
    var pluginData: ptr MyPlugin = cast[ptr MyPlugin](plugin.pluginData)

    assert(process.audioOutputsCount == 1)
    assert(process.audioInputsCount == 0)

    let frameCount: uint32 = process.framesCount
    let inputEventCount = process.inEvents.getEventCount()

    var eventIndex: uint32 = 0
    var nextEventFrame: uint32 = if inputEventCount != 0 : 0 else: frameCount
    var i: uint32 = 0
    while i < frameCount:
      while eventIndex < inputEventCount and nextEventFrame == i:
        let event = process.inEvents.getEvent(eventIndex)
        if not event.isNil:

          if event.time != i:
            nextEventFrame = event.time
            break

          PluginProcessEvent(pluginData, event)
          eventIndex += 1

        if eventIndex == inputEventCount:
          nextEventFrame = frameCount
          break

      for index in i..nextEventFrame:
        var sum: float = 0.0
        for j in 0..pluginData.voices.len:
          var voice = pluginData.voices[j]
          if not voice.held:
            continue
          sum += sin(voice.phase * 2.0 * 3.14159) * 0.2

          let phase: float = 440.0 * pow(2.0, (cast[float](voice.key) - 57.0) / 12.0 ) / pluginData.sampleRate

          voice.phase = phase
          voice.phase -= floor(voice.phase)

        process.audioOutputs[0].data32[0][index] = sum
        process.audioOutputs[0].data32[1][index] = sum

      i = nextEventFrame

    for i in 0..pluginData.voices.len:
      var voice = pluginData.voices[i]
      if not voice.held:
        var event: ClapEventNote
        event.header.size = cast[uint32](sizeof(event))
        event.header.time = 0
        event.header.space_id = CLAP_CORE_EVENT_SPACE_ID
        event.header.type = CLAP_EVENT_NOTE_END
        event.header.flags = 0
        event.key = voice.key
        event.note_id = voice.note_id
        event.channel = voice.channel
        event.port_index = 0
        discard process.outEvents.tryPush(process.outEvents, event.header.addr)
        pluginData.voices.del(i - 1)


    return CLAP_PROCESS_CONTINUE,
  get_extension: proc (plugin: ptr clap_plugin; id: cstring): pointer {.cdecl.} =
    if id == CLAP_EXT_NOTE_PORTS:
      return cast[pointer](extensionNotePorts.addr)
    if id == CLAP_EXT_AUDIO_PORTS:
      return cast[pointer](extensionAudioPorts.addr)
    return nil,
  on_main_thread: proc (plugin: ptr clap_plugin) {.cdecl.} =
    discard
)


var pluginFactory: ClapPluginFactory = ClapPluginFactory(
  get_plugin_count: proc(factory: ptr ClapPluginFactory): uint32 {.cdecl.} =
    return 1,
  get_plugin_descriptor: proc(factory: ptr ClapPluginFactory, index: uint32): ptr ClapPluginDescriptor {.cdecl.} =
    return if index == 0 : pluginDescriptor.addr else: nil,
  create_plugin: proc(factory: ptr ClapPluginFactory, host: ptr ClapHost, pluginId: cstring): ptr ClapPlugin {.cdecl.} =
    if not clapVersionIsCompatible(host.clapVersion) or pluginId!= pluginDescriptor.id:
      return nil
    var myPlugin: ptr MyPlugin = cast[ptr MyPlugin](allocShared0(sizeof(MyPlugin)))
    myPlugin.host = host
    myPlugin.plugin = pluginClass
    myPlugin.plugin.plugin_data = cast[pointer](myPlugin)
    return myPlugin.plugin.addr,
)


var clap_entry* {.exportc, dynlib.}: ClapPluginEntry = ClapPluginEntry(
    clap_version: CLAP_VERSION_INIT,
    init: proc(plugin_path: cstring): bool {.cdecl.} =
      return true,
    get_factory: proc(factoryId: cstring): pointer {.cdecl.} =
      return if factoryId == CLAP_PLUGIN_FACTORY_ID: cast[pointer](pluginFactory.addr) else: nil,
)