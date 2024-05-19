import ../src/nimclap

type Voice = object
  held: bool
  noteId: uint32
  channel: uint16
  key: uint16
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
  description: "Hello CLAP",
  features: allocCStringArray([
    CLAP_PLUGIN_FEATURE_AUDIO_EFFECT,
    CLAP_PLUGIN_FEATURE_MIXING,
    CLAP_PLUGIN_FEATURE_STEREO,
  ])
)

let myPluginExtensionNotePorts = ClapPluginNotePorts(
  count: proc(plugin: ptr ClapPlugin, isInput: bool): uint32 {.cdecl.} = 1,
  get: proc(plugin: ptr ClapPlugin, index: uint32, isInput: bool, info: ptr ClapNotePortInfo): bool {.cdecl} =
    if not isInput or index:
      return false
    info.id = 0,
    info.name = cast[array[CLAP_NAME_SIZE, char]]("My Port Name")

)


let pluginClass: ClapPlugin = ClapPlugin(
  desc: pluginDescriptor.addr,
  plugin_data: nil,
  init: proc(plugin: ptr clap_plugin): bool {.cdecl.} =
    #var pluginData: ptr MyPlugin = cast[ptr MyPlugin](plugin.plugin_data)
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
  process: proc (plugin: ptr clap_plugin; process: ptr clap_process): ClapProcessStatus {.cdecl.} =
    ## var pluginData: ptr MyPlugin = cast[ptr MyPlugin](plugin.plugin_data)
    ## todo
    return CLAP_PROCESS_CONTINUE,
  get_extension: proc (plugin: ptr clap_plugin; id: cstring): pointer {.cdecl.} =
    if id == CLAP_EXT_NOTE_PORTS:
      return myPluginExtensionNotePorts
    return nil,
  on_main_thread: proc (plugin: ptr clap_plugin) {.cdecl.} =
    discard
)


proc getMyPluginCount(factory: ptr ClapPluginFactory): uint32 {.cdecl.} =
  return 1

proc getMyPluginDescriptor(factory: ptr ClapPluginFactory; index: uint32): ptr ClapPluginDescriptor {.cdecl.} =
  return if index == 0 : addr pluginDescriptor else: nil


proc createMyPlugin(
  factory: ptr ClapPluginFactory,
  host: ptr ClapHost,
  pluginId: cstring,
): ptr ClapPlugin {.cdecl.} =
  if not clap_version_is_compatible(host.clapVersion) or pluginId != pluginDescriptor.id:
    return nil

  var myPlugin: MyPlugin = cast[MyPlugin](allocShared0(sizeof(MyPlugin)))
  myPlugin.host = host
  myPlugin.plugin = pluginClass
  myPlugin.plugin.plugin_data = cast[pointer](myPlugin.addr)
  return myPlugin.plugin.addr


var pluginFactory: ClapPluginFactory = ClapPluginFactory(
  get_plugin_count: getMyPluginCount,
  get_plugin_descriptor: getMyPluginDescriptor,
  create_plugin: createMyPlugin,
)


var clap_entry* {.exportc, dynlib.}: ClapPluginEntry = ClapPluginEntry(
    clap_version: CLAP_VERSION_INIT,
    init: proc(plugin_path: cstring): bool {.cdecl.} =
      return true,
    get_factory: proc(factoryId: cstring): pointer {.cdecl.} =
      return if factoryId == pluginDescriptor.id: cast[pointer](pluginFactory.addr) else: nil,
)