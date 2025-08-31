import ../src/nimclap
import std/math
import locks
import std/strutils


const parameterVolume = 0
const parameterCount = 1


type Voice = object
  held: bool
  noteId: int32
  channel: int16
  key: int16
  phase: float
  paramterOffsets: array[parameterCount, float64]


type MyPlugin = object
  plugin: ClapPlugin
  host: ptr ClapHost
  sampleRate: float
  voices: seq[Voice]
  parameters: array[parameterCount, float64]
  mainParameters: array[parameterCount, float64]
  changed: array[parameterCount, bool]
  mainChanged: array[parameterCount, bool]
  syncParameters: Lock


let pluginDescriptor* {.exportc.}: ClapPluginDescriptor = ClapPluginDescriptor(
  clap_version: CLAP_VERSION_INIT,
  id: "nakst.HelloCLAP2",
  name: "Hello CLAP 2",
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

proc PluginSyncMainToAudio(plugin: ptr MyPlugin, output: ptr ClapOutputEvents) =
  withLock(plugin.syncParameters):
    for i in 0..<parameterCount:
      if plugin.mainChanged[i]:
        plugin.parameters[i] = plugin.mainParameters[i]
        plugin.mainChanged[i] = false

        var event: ClapEventParamValue
        event.header.size = sizeof(event).uint32
        event.header.time = 0
        event.header.spaceId = clapCoreEventSpaceId
        event.header.`type` = ord(ClapEventTypes.paramValue)
        event.paramId = i.uint32
        event.cookie = nil
        event.noteId = -1
        event.portIndex = -1
        event.channel = -1
        event.key = -1
        event.value = plugin.parameters[i]
        discard output.tryPush(output, addr event.header)

proc PluginSyncAudioToMain(plugin: ptr MyPlugin): bool =
  var anyChanged = false
  withLock(plugin.syncParameters):
    for i in 0..<parameterCount:
      if plugin.changed[i]:
        plugin.mainParameters[i] = plugin.parameters[i]
        plugin.mainChanged[i] = false
        anyChanged = true

  return anyChanged


proc PluginProcessEvent(plugin: ptr MyPlugin, event: ptr ClapEventHeader) =
  if event.spaceId == clapCoreEventSpaceId:
    if event.type == ord(ClapEventTypes.noteOn) or event.type == ord(ClapEventTypes.noteOff) or event.type == ord(ClapEventTypes.noteChoke):
      let noteEvent = cast[ptr ClapEventNote](event)

      for i in countdown(plugin.voices.len - 1, 0):
        var voice = addr plugin.voices[i]
        if (noteEvent.key == -1 or voice.key == noteEvent.key) and (noteEvent.noteId == -1 or voice.noteId == noteEvent.noteId) and (noteEvent.channel == -1 or voice.channel == noteEvent.channel):
          if event.type == ord(ClapEventTypes.noteChoke):
            plugin.voices.del(i)
          else:
            voice.held = false

      if event.type == ord(ClapEventTypes.noteOn):
        var voice = Voice(
          held: true,
          noteId: noteEvent.noteId,
          channel: noteEvent.channel,
          key: noteEvent.key,
          phase: 0.0,
          paramterOffsets: [1.0]
        )
        plugin.voices.add(voice)

    if event.type == ord(ClapEventTypes.paramValue):
        let paramEvent = cast[ptr ClapEventParamValue](event)
        let id = paramEvent.paramId
        withLock(plugin.syncParameters):
          plugin.parameters[id] = paramEvent.value
          plugin.changed[id] = true

    if event.type == ord(ClapEventTypes.paramMod):
        let modEvent = cast[ptr ClapEventParamMod](event)
        for i in countdown(plugin.voices.len - 1, 0):
          var voice = addr plugin.voices[i]
          if (modEvent.key == -1 or voice.key == modEvent.key) and (modEvent.noteId == -1 or voice.noteId == modEvent.noteId) and (modEvent.channel == -1 or voice.channel == modEvent.channel):
            voice.paramterOffsets[modEvent.paramId] = modEvent.amount
            break





let extensionParams: ClapPluginParams = ClapPluginParams(
  count: proc (plugin: ptr clap_plugin): uint32 {.cdecl.} =
    return parameterCount,
  getInfo: proc (clapPlugin: ptr ClapPlugin; paramIndex: uint32;
                 paramInfo: ptr ClapParamInfo): bool {.cdecl.} =
    if paramIndex == parameterVolume:
      paramInfo.id = paramIndex
      paramInfo.flags = ord(CLAP_PARAM_IS_AUTOMATABLE ) or ord(CLAP_PARAM_IS_MODULATABLE) or ord(CLAP_PARAM_IS_MODULATABLE_PER_NOTE_ID)
      paramInfo.minValue = 0.0
      paramInfo.maxValue = 1.0
      paramInfo.defaultValue = 0.5
      paramInfo.name.setName("Volume")
      return true
    else:
      return false,
  getValue: proc (clapPlugin: ptr ClapPlugin; paramId: ClapId;
                  outValue: ptr cdouble): bool {.cdecl.} =
    var plugin: ptr MyPlugin = cast[ptr MyPlugin](clapPlugin.plugin_data)
    let i = uint32(paramId)
    if i >= parameterCount: return false
    withLock(plugin.syncParameters):
      outValue[] = if plugin.mainChanged[i]: plugin.mainParameters[i] else: plugin.parameters[i]
    return true,
  valueToText: proc (clapPlugin: ptr ClapPlugin; paramId: ClapId;
                        value: cdouble; outBuffer: cstring;
                        outBufferCapacity: uint32): bool {.cdecl.} =
    let i = uint32(paramId)
    if i >= parameterCount: return false
    let text = $"{value:0.2f}"
    let maxLen = if int(outBufferCapacity) < len(text) + 1: int(outBufferCapacity) else: len(text) + 1
    copyMem(outBuffer, text.cstring, maxLen)
    return true,
  textToValue: proc (clapPlugin: ptr ClapPlugin; paramId: ClapId;
                      paramValueText: cstring; outValue: ptr cdouble): bool {.cdecl.} =
    if paramId == parameterVolume:
      try:
        outValue[] = parseFloat($paramValueText)
        return true
      except ValueError:
        return false,
  flush: proc (clapPlugin: ptr ClapPlugin; inputEvents: ptr ClapInputEvents;
                  outputEvents: ptr ClapOutputEvents) {.cdecl.} =
    var plugin: ptr MyPlugin = cast[ptr MyPlugin](clapPlugin.plugin_data)
    let eventCount = inputEvents.size(inputEvents)

    PluginSyncMainToAudio(plugin, outputEvents)

    for i in 0..<eventCount:
      let event = inputEvents.get(inputEvents, i)
      PluginProcessEvent(plugin, event)

)






proc PluginRenderAudio(plugin: ptr MyPlugin, startIndex: uint32, endIndex: uint32, outputL: ptr UncheckedArray[cfloat], outputR: ptr UncheckedArray[cfloat]) =
  for index in startIndex..<endIndex:
    var sum: float = 0.0
    for i in 0..<plugin.voices.len:
      var voice = addr plugin.voices[i]
      if not voice.held:
        continue

      # calculate volume from parameters
      let volume = minMax01(plugin.parameters[parameterVolume] * voice.paramterOffsets[parameterVolume])

      # Generate sine wave sample
      sum += sin(voice.phase * 2.0 * PI) * 0.2 * volume

      # Calculate frequency and phase increment
      let frequency = keyNumberToFrequency(voice.key)
      let phaseIncrement = frequency / plugin.sampleRate

      # Advance phase
      voice.phase += phaseIncrement
      if voice.phase >= 1.0:
        voice.phase -= 1.0

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

let extensionState = ClapPluginState(
  save: proc (clapPlugin: ptr ClapPlugin; stream: ptr ClapOutStream): bool {.cdecl.} =
    let plugin = cast[ptr MyPlugin](clapPlugin.pluginData)
    discard PluginSyncAudioToMain(plugin)
    return sizeof(float) * parameterCount == stream.write(stream, plugin.mainParameters.addr, sizeof(float) * parameterCount),
  load: proc (clapPlugin: ptr ClapPlugin; stream: ptr ClapInStream): bool {.cdecl.} =
    var success: bool = false
    let plugin = cast[ptr MyPlugin](clapPlugin.pluginData)
    withLock(plugin.syncParameters):
      success = sizeof(float) * parameterCount == stream.read(stream, plugin.mainParameters.addr, sizeof(float) * parameterCount)
      for i in 0..<parameterCount:
        plugin.mainChanged[i] = true
    return success,
)


let pluginClass: ClapPlugin = ClapPlugin(
  desc: pluginDescriptor.addr,
  plugin_data: nil,
  init: proc(clapPlugin: ptr ClapPlugin): bool {.cdecl.} =
    var plugin: ptr MyPlugin = cast[ptr MyPlugin](clapPlugin.pluginData)
    initLock(plugin.syncParameters)
    for i in 0..<parameterCount:
      let paramInfo: ptr ClapParamInfo = cast[ptr ClapParamInfo](allocShared0(sizeof(ClapParamInfo)))
      if extensionParams.getInfo(clapPlugin, i.uint32, paramInfo):
        plugin.mainParameters[i] = paramInfo.defaultValue
        plugin.parameters[i] = paramInfo.defaultValue
      else:
        plugin.mainParameters[i] = 0.0
        plugin.parameters[i] = 0.0
    return true,
  destroy: proc(clapPlugin: ptr ClapPlugin) {.cdecl.} =
    var plugin: ptr MyPlugin = cast[ptr MyPlugin](clapPlugin.plugin_data)
    deinitLock(plugin.syncParameters)
    deallocShared(plugin),
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
  process: proc (clapPlugin: ptr ClapPlugin; process: ptr clap_process): ClapProcessStatus {.cdecl.} =
    var plugin: ptr MyPlugin = cast[ptr MyPlugin](clapPlugin.pluginData)
    PluginSyncMainToAudio(plugin, process.outEvents)

    assert(process.audioOutputsCount == 1)
    assert(process.audioInputsCount == 0)

    let frameCount: uint32 = process.framesCount
    let inputEventCount = process.inEvents.getEventCount()
    
    # Get output buffers
    let outputL = process.audioOutputs[0].addr.getChannelData32(0)
    let outputR = process.audioOutputs[0].addr.getChannelData32(1)

    var eventIndex: uint32 = 0
    var nextEventFrame: uint32 = if inputEventCount != 0: 0 else: frameCount

    var i: uint32 = 0
    while i < frameCount:
      # Process all events at the current time
      while eventIndex < inputEventCount and nextEventFrame == i:
        let event = process.inEvents.getEvent(eventIndex)
        if not event.isNil:
          if event.time != i:
            nextEventFrame = event.time
            break

          PluginProcessEvent(plugin, event)
          eventIndex += 1

          # Get next event time
          if eventIndex < inputEventCount:
            let nextEvent = process.inEvents.getEvent(eventIndex)
            if not nextEvent.isNil:
              nextEventFrame = nextEvent.time
            else:
              nextEventFrame = frameCount
          else:
            nextEventFrame = frameCount

      # Render audio from current position to next event
      PluginRenderAudio(plugin, i, nextEventFrame, outputL, outputR)
      i = nextEventFrame

    # Clean up finished voices
    var idx = plugin.voices.len
    while idx > 0:
      idx -= 1
      if not plugin.voices[idx].held:
        let voice = plugin.voices[idx]
        var event: ClapEventNote
        event.header.size = cast[uint32](sizeof(event))
        event.header.time = 0
        event.header.spaceId = clapCoreEventSpaceId
        event.header.`type` = ord(ClapEventTypes.noteOff)
        event.header.flags = 0
        event.key = voice.key
        event.noteId = voice.noteId
        event.channel = voice.channel
        event.portIndex = 0
        if process.outEvents.tryPushEvent(event.header.addr):
          plugin.voices.delete(idx)

    return CLAP_PROCESS_CONTINUE,
  get_extension: proc (plugin: ptr clap_plugin; id: cstring): pointer {.cdecl.} =
    if id == CLAP_EXT_NOTE_PORTS:
      return cast[pointer](extensionNotePorts.addr)
    if id == CLAP_EXT_AUDIO_PORTS:
      return cast[pointer](extensionAudioPorts.addr)
    if id == CLAP_EXT_PARAMS:
      return cast[pointer](extensionParams.addr)
    if id == CLAP_EXT_STATE:
      return cast[pointer](extensionState.addr)
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
    if not clapVersionIsCompatible(host.clapVersion) or pluginId != pluginDescriptor.id:
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