import ../src/nimclap

type Voice = object
  held: bool
  noteId: uint32
  channel: uint16
  key: uint16
  phase: float


type MyPlugin = object
  plugin: ClapPlugin
  host: ClapHost
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




proc getPluginCount(factory: ptr ClapPluginFactory): uint32 =
  return 1

proc getPluginDescriptor(factory: ptr ClapPluginFactory, index: uint32): ptr ClapPluginDescriptor =
  return if index == 0 : addr pluginDescriptor else: nil

proc createPlugin(
  factory: ptr ClapPluginFactory,
  host: ptr ClapHost,
  pluginId: cstring,
): ptr ClapPlugin =
  if not clap_version_is_compatible(host.clapVersion) or not pluginId == pluginDescriptor.id:
    return nil

  var plugin: MyPlugin = cast[ptr MyPlugin](allocShared0(sizeof(MyPlugin)))


const pluginFactory: ClapPluginFactory = {
  get_plugin_count: getPluginCount,
  get_plugin_descriptor: getPluginDescriptor,
  create_plugin: createPlugin,
}


const clap_entry* {.exportc, cdecl, dynlib.}: clap_plugin_entry = {
    clap_version: CLAP_VERSION_INIT,
    help: "Clap",
}