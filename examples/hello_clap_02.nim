## hello_clap_02.nim - a CLAP instrument in Nim with parameters and state.
##
## Based on nakst's CLAP tutorial: https://nakst.gitlab.io/tutorial/clap-part-1.html
## Ported to the current hand-maintained nimclap bindings.

import ../src/nimclap
import std/math
import locks
import std/strutils
import std/strformat

const parameterVolume = 0
const parameterCount = 1

type Voice = object
  held: bool
  noteId: int32
  channel: int16
  key: int16
  phase: float
  parameterOffsets: array[parameterCount, float64]

type MyPlugin = object
  plugin: Plugin
  host: ptr Host
  sampleRate: float
  voices: seq[Voice]
  parameters: array[parameterCount, float64]
  mainParameters: array[parameterCount, float64]
  changed: array[parameterCount, bool]
  mainChanged: array[parameterCount, bool]
  syncParameters: Lock

let pluginDescriptor* = PluginDescriptor(
  clapVersion: versionInit,
  id: "nakst.HelloCLAP2".cstring,
  name: "Hello CLAP 2".cstring,
  vendor: "nakst".cstring,
  url: "https://nakst.gitlab.io".cstring,
  manualUrl: "".cstring,
  supportUrl: "".cstring,
  version: "1.0.0".cstring,
  description: "The best audio plugin ever.".cstring,
  features: allocCStringArray([
    pluginFeatureInstrument,
    pluginFeatureSynthesizer,
    pluginFeatureStereo,
  ])
)

proc pluginSyncMainToAudio(plugin: ptr MyPlugin, output: ptr OutputEvents) =
  withLock(plugin.syncParameters):
    for i in 0 ..< parameterCount:
      if plugin.mainChanged[i]:
        plugin.parameters[i] = plugin.mainParameters[i]
        plugin.mainChanged[i] = false

        var event: EventParamValue
        event.header.size = sizeof(event).uint32
        event.header.time = 0
        event.header.spaceId = coreEventSpaceId
        event.header.`type` = eventParamValue.uint16
        event.paramId = i.Id
        event.cookie = nil
        event.noteId = -1
        event.portIndex = -1
        event.channel = -1
        event.key = -1
        event.value = plugin.parameters[i]
        discard output.tryPushEvent(addr event.header)

proc pluginSyncAudioToMain(plugin: ptr MyPlugin): bool =
  var anyChanged = false
  withLock(plugin.syncParameters):
    for i in 0 ..< parameterCount:
      if plugin.changed[i]:
        plugin.mainParameters[i] = plugin.parameters[i]
        plugin.mainChanged[i] = false
        anyChanged = true
  return anyChanged

proc pluginProcessEvent(plugin: ptr MyPlugin, event: ptr EventHeader) =
  if event.spaceId == coreEventSpaceId:
    if event.`type` == eventNoteOn.uint16 or
       event.`type` == eventNoteOff.uint16 or
       event.`type` == eventNoteChoke.uint16:
      let noteEvent = cast[ptr EventNote](event)

      for i in countdown(plugin.voices.len - 1, 0):
        var voice = addr plugin.voices[i]
        if (noteEvent.key == -1 or voice.key == noteEvent.key) and
           (noteEvent.noteId == -1 or voice.noteId == noteEvent.noteId) and
           (noteEvent.channel == -1 or voice.channel == noteEvent.channel):
          if event.`type` == eventNoteChoke.uint16:
            plugin.voices.del(i)
          else:
            voice.held = false

      if event.`type` == eventNoteOn.uint16:
        let voice = Voice(
          held: true,
          noteId: noteEvent.noteId,
          channel: noteEvent.channel,
          key: noteEvent.key,
          phase: 0.0,
          parameterOffsets: [1.0]
        )
        plugin.voices.add(voice)

    if event.`type` == eventParamValue.uint16:
      let paramEvent = cast[ptr EventParamValue](event)
      let id = paramEvent.paramId
      withLock(plugin.syncParameters):
        plugin.parameters[id] = paramEvent.value
        plugin.changed[id] = true

    if event.`type` == eventParamMod.uint16:
      let modEvent = cast[ptr EventParamMod](event)
      for i in countdown(plugin.voices.len - 1, 0):
        var voice = addr plugin.voices[i]
        if (modEvent.key == -1 or voice.key == modEvent.key) and
           (modEvent.noteId == -1 or voice.noteId == modEvent.noteId) and
           (modEvent.channel == -1 or voice.channel == modEvent.channel):
          voice.parameterOffsets[modEvent.paramId] = modEvent.amount
          break

let extensionParams = PluginParams(
  count: proc(plugin: ptr Plugin): uint32 {.cdecl.} =
    return parameterCount,
  getInfo: proc(plugin: ptr Plugin; paramIndex: uint32; paramInfo: ptr ParamInfo): bool {.cdecl.} =
    if paramIndex == parameterVolume:
      paramInfo.id = paramIndex.Id
      paramInfo.flags = (paramIsAutomatable or paramIsModulatable or
                         paramIsModulatablePerNoteId).uint32
      paramInfo.minValue = 0.0
      paramInfo.maxValue = 1.0
      paramInfo.defaultValue = 0.5
      paramInfo.name.setName("Volume")
      return true
    else:
      return false,
  getValue: proc(plugin: ptr Plugin; paramId: Id; outValue: ptr cdouble): bool {.cdecl.} =
    let pluginData = cast[ptr MyPlugin](plugin.pluginData)
    let i = uint32(paramId)
    if i >= parameterCount: return false
    withLock(pluginData.syncParameters):
      outValue[] = if pluginData.mainChanged[i]: pluginData.mainParameters[i]
                   else: pluginData.parameters[i]
    return true,
  valueToText: proc(plugin: ptr Plugin; paramId: Id; value: cdouble;
                    outBuffer: cstring; outBufferCapacity: uint32): bool {.cdecl.} =
    let i = uint32(paramId)
    if i >= parameterCount: return false
    let text = &"{value:0.2f}"
    let maxLen = if int(outBufferCapacity) < len(text) + 1: int(outBufferCapacity)
                 else: len(text) + 1
    copyMem(outBuffer, text.cstring, maxLen)
    return true,
  textToValue: proc(plugin: ptr Plugin; paramId: Id; paramValueText: cstring;
                    outValue: ptr cdouble): bool {.cdecl.} =
    if paramId == parameterVolume.Id:
      try:
        outValue[] = parseFloat($paramValueText)
        return true
      except ValueError:
        return false
    return false,
  flush: proc(plugin: ptr Plugin; `in`: ptr InputEvents; `out`: ptr OutputEvents) {.cdecl.} =
    let pluginData = cast[ptr MyPlugin](plugin.pluginData)
    let eventCount = `in`.getEventCount()

    pluginSyncMainToAudio(pluginData, `out`)

    for i in 0 ..< eventCount:
      let event = `in`.getEvent(i)
      if not event.isNil:
        pluginProcessEvent(pluginData, event)
)

proc pluginRenderAudio(plugin: ptr MyPlugin, startIndex: uint32, endIndex: uint32,
                       outputL: ptr UncheckedArray[cfloat], outputR: ptr UncheckedArray[cfloat]) =
  if outputL.isNil or outputR.isNil:
    return
  for index in startIndex ..< endIndex:
    var sum: float = 0.0
    for i in 0 ..< plugin.voices.len:
      var voice = addr plugin.voices[i]
      if not voice.held:
        continue

      # Calculate volume from parameters
      let volume = minMax01(plugin.parameters[parameterVolume] *
                            voice.parameterOffsets[parameterVolume])

      # Generate sine wave sample
      sum += sin(voice.phase * 2.0 * PI) * 0.2 * volume

      # Calculate frequency and phase increment
      let frequency = keyNumberToFrequency(voice.key.int)
      let phaseIncrement = frequency / plugin.sampleRate

      # Advance phase
      voice.phase += phaseIncrement
      if voice.phase >= 1.0:
        voice.phase -= 1.0

    outputL[index] = sum.cfloat
    outputR[index] = sum.cfloat

let extensionNotePorts = PluginNotePorts(
  count: proc(plugin: ptr Plugin, isInput: bool): uint32 {.cdecl.} =
    return if isInput: 1 else: 0,
  get: proc(plugin: ptr Plugin, index: uint32, isInput: bool, info: ptr NotePortInfo): bool {.cdecl.} =
    if not isInput or index > 0:
      return false
    info.id = 0
    info.name.setName("Note Input Port")
    info.supportedDialects = NoteDialect.dialectClap.ord.uint32
    info.preferredDialect = NoteDialect.dialectClap.ord.uint32
    return true
)

let extensionAudioPorts = PluginAudioPorts(
  count: proc(plugin: ptr Plugin, isInput: bool): uint32 {.cdecl.} =
    return if isInput: 0 else: 1,
  get: proc(plugin: ptr Plugin, index: uint32, isInput: bool, info: ptr AudioPortInfo): bool {.cdecl.} =
    if isInput or index > 0:
      return false
    info.id = 0
    info.channelCount = 2
    info.flags = audioPortIsMain
    info.portType = portStereo
    info.inPlacePair = invalidId
    info.name.setName("Audio Output Port")
    return true
)

let extensionState = PluginState(
  save: proc(plugin: ptr Plugin; stream: ptr Ostream): bool {.cdecl.} =
    let pluginData = cast[ptr MyPlugin](plugin.pluginData)
    discard pluginSyncAudioToMain(pluginData)
    let nbytes = uint64(sizeof(float) * parameterCount)
    return stream.write(stream, pluginData.mainParameters.addr, nbytes) == nbytes.int64,
  load: proc(plugin: ptr Plugin; stream: ptr Istream): bool {.cdecl.} =
    var success = false
    let pluginData = cast[ptr MyPlugin](plugin.pluginData)
    let nbytes = uint64(sizeof(float) * parameterCount)
    withLock(pluginData.syncParameters):
      success = stream.read(stream, pluginData.mainParameters.addr, nbytes) == nbytes.int64
      for i in 0 ..< parameterCount:
        pluginData.mainChanged[i] = true
    return success,
)

let pluginClass: Plugin = Plugin(
  desc: pluginDescriptor.addr,
  pluginData: nil,
  init: proc(plugin: ptr Plugin): bool {.cdecl.} =
    let pluginData = cast[ptr MyPlugin](plugin.pluginData)
    initLock(pluginData.syncParameters)
    for i in 0 ..< parameterCount:
      let paramInfo = cast[ptr ParamInfo](allocShared0(sizeof(ParamInfo)))
      if extensionParams.getInfo(plugin, i.uint32, paramInfo):
        pluginData.mainParameters[i] = paramInfo.defaultValue
        pluginData.parameters[i] = paramInfo.defaultValue
      else:
        pluginData.mainParameters[i] = 0.0
        pluginData.parameters[i] = 0.0
      deallocShared(paramInfo)
    return true,
  destroy: proc(plugin: ptr Plugin) {.cdecl.} =
    let pluginData = cast[ptr MyPlugin](plugin.pluginData)
    deinitLock(pluginData.syncParameters)
    deallocShared(pluginData),
  activate: proc(plugin: ptr Plugin; sampleRate: cdouble; minimumFramesCount: uint32; maximumFramesCount: uint32): bool {.cdecl.} =
    let pluginData = cast[ptr MyPlugin](plugin.pluginData)
    pluginData.sampleRate = sampleRate
    return true,
  deactivate: proc(plugin: ptr Plugin) {.cdecl.} =
    discard,
  startProcessing: proc(plugin: ptr Plugin): bool {.cdecl.} =
    return true,
  stopProcessing: proc(plugin: ptr Plugin) {.cdecl.} =
    discard,
  reset: proc(plugin: ptr Plugin) {.cdecl.} =
    let pluginData = cast[ptr MyPlugin](plugin.pluginData)
    pluginData.voices.setLen(0),
  process: proc(plugin: ptr Plugin; process: ptr Process): ProcessStatus {.cdecl.} =
    let pluginData = cast[ptr MyPlugin](plugin.pluginData)
    pluginSyncMainToAudio(pluginData, process.outEvents)

    assert(process.audioOutputsCount == 1)

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

          pluginProcessEvent(pluginData, event)
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
        else:
          break

      # Render audio from current position to next event
      pluginRenderAudio(pluginData, i, nextEventFrame, outputL, outputR)
      i = nextEventFrame

    # Clean up finished voices
    var idx = pluginData.voices.len
    while idx > 0:
      idx -= 1
      if not pluginData.voices[idx].held:
        let voice = pluginData.voices[idx]
        var event: EventNote
        event.header.size = cast[uint32](sizeof(event))
        event.header.time = 0
        event.header.spaceId = coreEventSpaceId
        event.header.`type` = eventNoteEnd.uint16
        event.header.flags = 0
        event.key = voice.key
        event.noteId = voice.noteId
        event.channel = voice.channel
        event.portIndex = 0
        if process.outEvents.tryPushEvent(event.header.addr):
          pluginData.voices.delete(idx)

    return processContinue,
  getExtension: proc(plugin: ptr Plugin; id: cstring): pointer {.cdecl.} =
    if id == extNotePorts:
      return cast[pointer](extensionNotePorts.addr)
    if id == extAudioPorts:
      return cast[pointer](extensionAudioPorts.addr)
    if id == extParams:
      return cast[pointer](extensionParams.addr)
    if id == extState:
      return cast[pointer](extensionState.addr)
    return nil,
  onMainThread: proc(plugin: ptr Plugin) {.cdecl.} =
    discard
)

var pluginFactory: PluginFactory = PluginFactory(
  getPluginCount: proc(factory: ptr PluginFactory): uint32 {.cdecl.} =
    return 1,
  getPluginDescriptor: proc(factory: ptr PluginFactory, index: uint32): ptr PluginDescriptor {.cdecl.} =
    return if index == 0: pluginDescriptor.addr else: nil,
  createPlugin: proc(factory: ptr PluginFactory, host: ptr Host, pluginId: cstring): ptr Plugin {.cdecl.} =
    if not versionIsCompatible(host.clapVersion) or pluginId != pluginDescriptor.id:
      return nil
    var myPlugin = cast[ptr MyPlugin](allocShared0(sizeof(MyPlugin)))
    myPlugin.host = host
    myPlugin.plugin = pluginClass
    myPlugin.plugin.pluginData = cast[pointer](myPlugin)
    return myPlugin.plugin.addr,
)

var clap_entry* {.exportc, dynlib.}: PluginEntry = PluginEntry(
  clapVersion: versionInit,
  init: proc(pluginPath: cstring): bool {.cdecl.} =
    return true,
  deinit: proc() {.cdecl.} =
    discard,
  getFactory: proc(factoryId: cstring): pointer {.cdecl.} =
    return if factoryId == pluginFactoryId: cast[pointer](pluginFactory.addr) else: nil,
)
