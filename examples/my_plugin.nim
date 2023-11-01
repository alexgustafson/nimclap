import ../src/nimclap


let myPluginDescriptor: ClapPluginDescriptor = ClapPluginDescriptor(
    clapVersion: CLAP_VERSION,
    id: "com.example.my-plugin".cstring,
    name: "My Plugin".cstring,
    vendor: "My Company".cstring,
    url: "https://your-domain.com/my-plugin".cstring,
    manualUrl: "https://your-domain.com/my-plugin/manual".cstring,
    supportUrl: "https://your-domain.com/support".cstring,
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