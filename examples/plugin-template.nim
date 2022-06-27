##  This file is here to demonstrate how to wire a CLAP plugin
##  You can use it as a starting point, however if you are implementing a C++
##  plugin, I'd encourage you to use the C++ glue layer instead:
##  https://github.com/free-audio/clap-helpers/blob/main/include/clap/helpers/plugin.hh

var sMyPlugDesc*: ClapPluginDescriptorT = [clapVersion: clap_Version_Init,
                                       id: "com.your-company.YourPlugin",
                                       name: "Plugin Name", vendor: "Vendor", url: "https://your-domain.com/your-plugin", manualUrl: "https://your-domain.com/your-plugin/manual", supportUrl: "https://your-domain.com/support",
                                       version: "1.4.2",
                                       description: "The plugin description.", features: cast[UncheckedArray[
    cstring]]((clap_Plugin_Feature_Instrument, clap_Plugin_Feature_Stereo, nil))]

type
  MyPlugT* {.bycopy.} = object
    plugin*: ClapPluginT
    host*: ptr ClapHostT
    hostLatency*: ptr ClapHostLatencyT
    hostLog*: ptr ClapHostLogT
    hostThreadCheck*: ptr ClapHostThreadCheckT
    latency*: uint32T


## ///////////////////////////
##  clap_plugin_audio_ports //
## ///////////////////////////

proc myPlugAudioPortsCount*(plugin: ptr ClapPluginT; isInput: bool): uint32T =
  return 1

proc myPlugAudioPortsGet*(plugin: ptr ClapPluginT; index: uint32T; isInput: bool;
                         info: ptr ClapAudioPortInfoT): bool =
  if index > 0:
    return false
  info.id = 0
  snprintf(info.name, sizeof((info.name)), "%s", "My Port Name")
  info.channelCount = 2
  info.flags = clap_Audio_Port_Is_Main
  info.portType = clap_Port_Stereo
  info.inPlacePair = clap_Invalid_Id
  return true

var sMyPlugAudioPorts*: ClapPluginAudioPortsT = [count: myPlugAudioPortsCount,
    get: myPlugAudioPortsGet]

## //////////////////////////
##  clap_plugin_note_ports //
## //////////////////////////

proc myPlugNotePortsCount*(plugin: ptr ClapPluginT; isInput: bool): uint32T =
  return 1

proc myPlugNotePortsGet*(plugin: ptr ClapPluginT; index: uint32T; isInput: bool;
                        info: ptr ClapNotePortInfoT): bool =
  if index > 0:
    return false
  info.id = 0
  snprintf(info.name, sizeof((info.name)), "%s", "My Port Name")
  info.supportedDialects = clap_Note_Dialect_Clap or clap_Note_Dialect_Midi_Mpe or
      clap_Note_Dialect_Midi2
  info.preferredDialect = clap_Note_Dialect_Clap
  return true

var sMyPlugNotePorts*: ClapPluginNotePortsT = [count: myPlugNotePortsCount,
    get: myPlugNotePortsGet]

## ////////////////
##  clap_latency //
## ////////////////

proc myPlugLatencyGet*(plugin: ptr ClapPluginT): uint32T =
  var plug: ptr MyPlugT = plugin.pluginData
  return plug.latency

var sMyPlugLatency*: ClapPluginLatencyT = [get: myPlugLatencyGet]

## ///////////////
##  clap_plugin //
## ///////////////

proc myPlugInit*(plugin: ptr ClapPlugin): bool =
  var plug: ptr MyPlugT = plugin.pluginData
  ##  Fetch host's extensions here
  plug.hostLog = plug.host.getExtension(plug.host, clap_Ext_Log)
  plug.hostThreadCheck = plug.host.getExtension(plug.host, clap_Ext_Thread_Check)
  plug.hostLatency = plug.host.getExtension(plug.host, clap_Ext_Latency)
  return true

proc myPlugDestroy*(plugin: ptr ClapPlugin) =
  discard

proc myPlugActivate*(plugin: ptr ClapPlugin; sampleRate: cdouble;
                    minFramesCount: uint32T; maxFramesCount: uint32T): bool =
  return true

proc myPlugDeactivate*(plugin: ptr ClapPlugin) =
  discard

proc myPlugStartProcessing*(plugin: ptr ClapPlugin): bool =
  return true

proc myPlugStopProcessing*(plugin: ptr ClapPlugin) =
  discard

proc myPlugReset*(plugin: ptr ClapPlugin) =
  discard

proc myPlugProcessEvent*(plug: ptr MyPlugT; hdr: ptr ClapEventHeaderT) =
  if hdr.spaceId == clap_Core_Event_Space_Id:
    case hdr.`type`
    of clap_Event_Note_On:
      var ev: ptr ClapEventNoteT = cast[ptr ClapEventNoteT](hdr)
      ##  TODO: handle note on
      break
    of clap_Event_Note_Off:
      var ev: ptr ClapEventNoteT = cast[ptr ClapEventNoteT](hdr)
      ##  TODO: handle note on
      break
    of clap_Event_Note_Choke:
      var ev: ptr ClapEventNoteT = cast[ptr ClapEventNoteT](hdr)
      ##  TODO: handle note choke
      break
    of clap_Event_Note_Expression:
      var ev: ptr ClapEventNoteExpressionT = cast[ptr ClapEventNoteExpressionT](hdr)
      ##  TODO: handle note expression
      break
    of clap_Event_Param_Value:
      var ev: ptr ClapEventParamValueT = cast[ptr ClapEventParamValueT](hdr)
      ##  TODO: handle parameter change
      break
    of clap_Event_Param_Mod:
      var ev: ptr ClapEventParamModT = cast[ptr ClapEventParamModT](hdr)
      ##  TODO: handle parameter modulation
      break
    of clap_Event_Transport:
      var ev: ptr ClapEventTransportT = cast[ptr ClapEventTransportT](hdr)
      ##  TODO: handle transport event
      break
    of clap_Event_Midi:
      var ev: ptr ClapEventMidiT = cast[ptr ClapEventMidiT](hdr)
      ##  TODO: handle MIDI event
      break
    of clap_Event_Midi_Sysex:
      var ev: ptr ClapEventMidiSysexT = cast[ptr ClapEventMidiSysexT](hdr)
      ##  TODO: handle MIDI Sysex event
      break
    of clap_Event_Midi2:
      var ev: ptr ClapEventMidi2T = cast[ptr ClapEventMidi2T](hdr)
      ##  TODO: handle MIDI2 event
      break

proc myPlugProcess*(plugin: ptr ClapPlugin; process: ptr ClapProcessT): ClapProcessStatus =
  var plug: ptr MyPlugT = plugin.pluginData
  var nframes: uint32T = process.framesCount
  var nev: uint32T = process.inEvents.size(process.inEvents)
  var evIndex: uint32T = 0
  var nextEvFrame: uint32T = if nev > 0: 0 else: nframes
  var i: uint32T = 0
  while i < nframes:
    ##  handle every events that happrens at the frame "i"
    while evIndex < nev and nextEvFrame == i:
      var hdr: ptr ClapEventHeaderT = process.inEvents.get(process.inEvents, evIndex)
      if hdr.time != i:
        nextEvFrame = hdr.time
        break
      myPlugProcessEvent(plug, hdr)
      inc(evIndex)
      if evIndex == nev:
        ##  we reached the end of the event list
        nextEvFrame = nframes
        break
    ##  process every samples until the next event
    while i < nextEvFrame:
      ##  fetch input samples
      var inL: cfloat = process.audioInputs[0].data32[0][i]
      var inR: cfloat = process.audioInputs[0].data32[1][i]
      ##  TODO: process samples, here we simply swap left and right channels
      var outL: cfloat = inR
      var outR: cfloat = inL
      ##  store output samples
      process.audioOutputs[0].data32[0][i] = outL
      process.audioOutputs[0].data32[1][i] = outR
      inc(i)
  return clap_Process_Continue

proc myPlugGetExtension*(plugin: ptr ClapPlugin; id: cstring): pointer =
  if not strcmp(id, clap_Ext_Latency):
    return addr(sMyPlugLatency)
  if not strcmp(id, clap_Ext_Audio_Ports):
    return addr(sMyPlugAudioPorts)
  if not strcmp(id, clap_Ext_Note_Ports):
    return addr(sMyPlugNotePorts)
  return nil

proc myPlugOnMainThread*(plugin: ptr ClapPlugin) =
  discard

proc myPlugCreate*(host: ptr ClapHostT): ptr ClapPluginT =
  var p: ptr MyPlugT = calloc(1, sizeof((p[])))
  p.host = host
  p.plugin.desc = addr(sMyPlugDesc)
  p.plugin.pluginData = p
  p.plugin.init = myPlugInit
  p.plugin.destroy = myPlugDestroy
  p.plugin.activate = myPlugActivate
  p.plugin.deactivate = myPlugDeactivate
  p.plugin.startProcessing = myPlugStartProcessing
  p.plugin.stopProcessing = myPlugStopProcessing
  p.plugin.reset = myPlugReset
  p.plugin.process = myPlugProcess
  p.plugin.getExtension = myPlugGetExtension
  p.plugin.onMainThread = myPlugOnMainThread
  ##  Don't call into the host here
  return addr(p.plugin)

## ///////////////////////
##  clap_plugin_factory //
## ///////////////////////

## !!!Ignored construct:  static struct { const clap_plugin_descriptor_t * desc ; clap_plugin_t * ( * create ) ( const clap_host_t * host ) ; } s_plugins [ ] = { { . desc = & s_my_plug_desc , . create = my_plug_create , } , } ;
## Error: identifier expected, but got: {!!!

proc pluginFactoryGetPluginCount*(factory: ptr ClapPluginFactory): uint32T =
  return sizeof((sPlugins) div sizeof((sPlugins[0])))

proc pluginFactoryGetPluginDescriptor*(factory: ptr ClapPluginFactory;
                                      index: uint32T): ptr ClapPluginDescriptorT =
  return sPlugins[index].desc

proc pluginFactoryCreatePlugin*(factory: ptr ClapPluginFactory; host: ptr ClapHostT;
                               pluginId: cstring): ptr ClapPluginT =
  if not clapVersionIsCompatible(host.clapVersion):
    return nil
  var N: cint = sizeof((sPlugins) div sizeof((sPlugins[0])))
  var i: cint = 0
  while i < n:
    if not strcmp(pluginId, sPlugins[i].desc.id):
      return sPlugins[i].create(host)
    inc(i)
  return nil

var sPluginFactory*: ClapPluginFactoryT = [getPluginCount: pluginFactoryGetPluginCount, getPluginDescriptor: pluginFactoryGetPluginDescriptor,
                                       createPlugin: pluginFactoryCreatePlugin]

## //////////////
##  clap_entry //
## //////////////

proc entryInit*(pluginPath: cstring): bool =
  ##  called only once, and very first
  return true

proc entryDeinit*() =
  ##  called before unloading the DSO

proc entryGetFactory*(factoryId: cstring): pointer =
  if not strcmp(factoryId, clap_Plugin_Factory_Id):
    return addr(sPluginFactory)
  return nil

## !!!Ignored construct:  CLAP_EXPORT const clap_plugin_entry_t clap_entry = { . clap_version = CLAP_VERSION_INIT , . init = entry_init , . deinit = entry_deinit , . get_factory = entry_get_factory , } ;
## Error: token expected: ; but got: [identifier]!!!
