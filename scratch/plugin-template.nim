##  This file is here to demonstrate how to wire a CLAP plugin
##  You can use it as a starting point, however if you are implementing a C++
##  plugin, I'd encourage you to use the C++ glue layer instead:
##  https://github.com/free-audio/clap-helpers/blob/main/include/clap/helpers/plugin.hh

let s_my_plug_desc*: clap_plugin_descriptor_t = [clap_version: CLAP_VERSION_INIT,
    id: "com.your-company.YourPlugin", name: "Plugin Name", vendor: "Vendor",
    url: "https://your-domain.com/your-plugin",
    manual_url: "https://your-domain.com/your-plugin/manual",
    support_url: "https://your-domain.com/support", version: "1.4.2",
    description: "The plugin description.", features: cast[UncheckedArray[cstring]]((
    CLAP_PLUGIN_FEATURE_INSTRUMENT, CLAP_PLUGIN_FEATURE_STEREO, nil))]

type
  my_plug_t* {.bycopy.} = object
    plugin*: clap_plugin_t
    host*: ptr clap_host_t
    host_latency*: ptr clap_host_latency_t
    host_log*: ptr clap_host_log_t
    host_thread_check*: ptr clap_host_thread_check_t
    host_state*: ptr clap_host_state_t
    latency*: uint32_t


## //////////////////////////
##  clap_plugin_audio_ports //
## //////////////////////////

proc my_plug_audio_ports_count*(plugin: ptr clap_plugin_t; is_input: bool): uint32_t {.
    cdecl.} =
  ##  We just declare 1 audio input and 1 audio output
  return 1

proc my_plug_audio_ports_get*(plugin: ptr clap_plugin_t; index: uint32_t;
                             is_input: bool; info: ptr clap_audio_port_info_t): bool {.
    cdecl.} =
  if index > 0:
    return false
  info.id = 0
  snprintf(info.name, sizeof((info.name)), "%s", "My Port Name")
  info.channel_count = 2
  info.flags = CLAP_AUDIO_PORT_IS_MAIN
  info.port_type = CLAP_PORT_STEREO
  info.in_place_pair = CLAP_INVALID_ID
  return true

let s_my_plug_audio_ports*: clap_plugin_audio_ports_t = [
    count: my_plug_audio_ports_count, get: my_plug_audio_ports_get]

## /////////////////////////
##  clap_plugin_note_ports //
## /////////////////////////

proc my_plug_note_ports_count*(plugin: ptr clap_plugin_t; is_input: bool): uint32_t {.
    cdecl.} =
  ##  We just declare 1 note input
  return 1

proc my_plug_note_ports_get*(plugin: ptr clap_plugin_t; index: uint32_t;
                            is_input: bool; info: ptr clap_note_port_info_t): bool {.
    cdecl.} =
  if index > 0:
    return false
  info.id = 0
  snprintf(info.name, sizeof((info.name)), "%s", "My Port Name")
  info.supported_dialects = CLAP_NOTE_DIALECT_CLAP or CLAP_NOTE_DIALECT_MIDI_MPE or
      CLAP_NOTE_DIALECT_MIDI2
  info.preferred_dialect = CLAP_NOTE_DIALECT_CLAP
  return true

let s_my_plug_note_ports*: clap_plugin_note_ports_t = [
    count: my_plug_note_ports_count, get: my_plug_note_ports_get]

## ///////////////
##  clap_latency //
## ///////////////

proc my_plug_latency_get*(plugin: ptr clap_plugin_t): uint32_t {.cdecl.} =
  var plug: ptr my_plug_t = plugin.plugin_data
  return plug.latency

let s_my_plug_latency*: clap_plugin_latency_t = [get: my_plug_latency_get]

## /////////////
##  clap_state //
## /////////////

proc my_plug_state_save*(plugin: ptr clap_plugin_t; stream: ptr clap_ostream_t): bool {.
    cdecl.} =
  var plug: ptr my_plug_t = plugin.plugin_data
  ##  TODO: write the state into stream
  return true

proc my_plug_state_load*(plugin: ptr clap_plugin_t; stream: ptr clap_istream_t): bool {.
    cdecl.} =
  var plug: ptr my_plug_t = plugin.plugin_data
  ##  TODO: read the state from stream
  return true

let s_my_plug_state*: clap_plugin_state_t = [save: my_plug_state_save,
    load: my_plug_state_load]

## //////////////
##  clap_plugin //
## //////////////

proc my_plug_init*(plugin: ptr clap_plugin): bool {.cdecl.} =
  var plug: ptr my_plug_t = plugin.plugin_data
  ##  Fetch host's extensions here
  ##  Make sure to check that the interface functions are not null pointers
  plug.host_log = cast[ptr clap_host_log_t](plug.host.get_extension(plug.host,
      CLAP_EXT_LOG))
  plug.host_thread_check = cast[ptr clap_host_thread_check_t](plug.host.get_extension(
      plug.host, CLAP_EXT_THREAD_CHECK))
  plug.host_latency = cast[ptr clap_host_latency_t](plug.host.get_extension(
      plug.host, CLAP_EXT_LATENCY))
  plug.host_state = cast[ptr clap_host_state_t](plug.host.get_extension(plug.host,
      CLAP_EXT_STATE))
  return true

proc my_plug_destroy*(plugin: ptr clap_plugin) {.cdecl.} =
  var plug: ptr my_plug_t = plugin.plugin_data
  free(plug)

proc my_plug_activate*(plugin: ptr clap_plugin; sample_rate: cdouble;
                      min_frames_count: uint32_t; max_frames_count: uint32_t): bool {.
    cdecl.} =
  return true

proc my_plug_deactivate*(plugin: ptr clap_plugin) {.cdecl.} =
  discard

proc my_plug_start_processing*(plugin: ptr clap_plugin): bool {.cdecl.} =
  return true

proc my_plug_stop_processing*(plugin: ptr clap_plugin) {.cdecl.} =
  discard

proc my_plug_reset*(plugin: ptr clap_plugin) {.cdecl.} =
  discard

proc my_plug_process_event*(plug: ptr my_plug_t; hdr: ptr clap_event_header_t) {.cdecl.} =
  if hdr.space_id == CLAP_CORE_EVENT_SPACE_ID:
    case hdr.`type`
    of CLAP_EVENT_NOTE_ON:
      let ev: ptr clap_event_note_t = cast[ptr clap_event_note_t](hdr)
      ##  TODO: handle note on
      break
    of CLAP_EVENT_NOTE_OFF:
      let ev: ptr clap_event_note_t = cast[ptr clap_event_note_t](hdr)
      ##  TODO: handle note off
      break
    of CLAP_EVENT_NOTE_CHOKE:
      let ev: ptr clap_event_note_t = cast[ptr clap_event_note_t](hdr)
      ##  TODO: handle note choke
      break
    of CLAP_EVENT_NOTE_EXPRESSION:
      let ev: ptr clap_event_note_expression_t = cast[ptr clap_event_note_expression_t](hdr)
      ##  TODO: handle note expression
      break
    of CLAP_EVENT_PARAM_VALUE:
      let ev: ptr clap_event_param_value_t = cast[ptr clap_event_param_value_t](hdr)
      ##  TODO: handle parameter change
      break
    of CLAP_EVENT_PARAM_MOD:
      let ev: ptr clap_event_param_mod_t = cast[ptr clap_event_param_mod_t](hdr)
      ##  TODO: handle parameter modulation
      break
    of CLAP_EVENT_TRANSPORT:
      let ev: ptr clap_event_transport_t = cast[ptr clap_event_transport_t](hdr)
      ##  TODO: handle transport event
      break
    of CLAP_EVENT_MIDI:
      let ev: ptr clap_event_midi_t = cast[ptr clap_event_midi_t](hdr)
      ##  TODO: handle MIDI event
      break
    of CLAP_EVENT_MIDI_SYSEX:
      let ev: ptr clap_event_midi_sysex_t = cast[ptr clap_event_midi_sysex_t](hdr)
      ##  TODO: handle MIDI Sysex event
      break
    of CLAP_EVENT_MIDI2:
      let ev: ptr clap_event_midi2_t = cast[ptr clap_event_midi2_t](hdr)
      ##  TODO: handle MIDI2 event
      break

proc my_plug_process*(plugin: ptr clap_plugin; process: ptr clap_process_t): clap_process_status {.
    cdecl.} =
  var plug: ptr my_plug_t = plugin.plugin_data
  let nframes: uint32_t = process.frames_count
  let nev: uint32_t = process.in_events.size(process.in_events)
  var ev_index: uint32_t = 0
  var next_ev_frame: uint32_t = if nev > 0: 0 else: nframes
  var i: uint32_t = 0
  while i < nframes:
    ##  handle every events that happrens at the frame "i"
    while ev_index < nev and next_ev_frame == i:
      let hdr: ptr clap_event_header_t = process.in_events.get(process.in_events,
          ev_index)
      if hdr.time != i:
        next_ev_frame = hdr.time
        break
      my_plug_process_event(plug, hdr)
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

proc my_plug_get_extension*(plugin: ptr clap_plugin; id: cstring): pointer {.cdecl.} =
  if not strcmp(id, CLAP_EXT_LATENCY):
    return addr(s_my_plug_latency)
  if not strcmp(id, CLAP_EXT_AUDIO_PORTS):
    return addr(s_my_plug_audio_ports)
  if not strcmp(id, CLAP_EXT_NOTE_PORTS):
    return addr(s_my_plug_note_ports)
  if not strcmp(id, CLAP_EXT_STATE):
    return addr(s_my_plug_state)
  return nil

proc my_plug_on_main_thread*(plugin: ptr clap_plugin) {.cdecl.} =
  discard

proc my_plug_create*(host: ptr clap_host_t): ptr clap_plugin_t {.cdecl.} =
  var p: ptr my_plug_t = calloc(1, sizeof((p[])))
  p.host = host
  p.plugin.desc = addr(s_my_plug_desc)
  p.plugin.plugin_data = p
  p.plugin.init = my_plug_init
  p.plugin.destroy = my_plug_destroy
  p.plugin.activate = my_plug_activate
  p.plugin.deactivate = my_plug_deactivate
  p.plugin.start_processing = my_plug_start_processing
  p.plugin.stop_processing = my_plug_stop_processing
  p.plugin.reset = my_plug_reset
  p.plugin.process = my_plug_process
  p.plugin.get_extension = my_plug_get_extension
  p.plugin.on_main_thread = my_plug_on_main_thread
  ##  Don't call into the host here
  return addr(p.plugin)

## //////////////////////
##  clap_plugin_factory //
## //////////////////////

## !!!Ignored construct:  static struct { const clap_plugin_descriptor_t * desc ; clap_plugin_t * ( CLAP_ABI * create ) ( const clap_host_t * host ) ; } s_plugins [ ] = { { . desc = & s_my_plug_desc , . create = my_plug_create , } , } ;
## Error: identifier expected, but got: {!!!

proc plugin_factory_get_plugin_count*(factory: ptr clap_plugin_factory): uint32_t {.
    cdecl.} =
  return sizeof((s_plugins) div sizeof((s_plugins[0])))

proc plugin_factory_get_plugin_descriptor*(factory: ptr clap_plugin_factory;
    index: uint32_t): ptr clap_plugin_descriptor_t {.cdecl.} =
  return s_plugins[index].desc

proc plugin_factory_create_plugin*(factory: ptr clap_plugin_factory;
                                  host: ptr clap_host_t; plugin_id: cstring): ptr clap_plugin_t {.
    cdecl.} =
  if not clap_version_is_compatible(host.clap_version):
    return nil
  let N: cint = sizeof((s_plugins) div sizeof((s_plugins[0])))
  var i: cint = 0
  while i < N:
    if not strcmp(plugin_id, s_plugins[i].desc.id):
      return s_plugins[i].create(host)
    inc(i)
  return nil

let s_plugin_factory*: clap_plugin_factory_t = [
    get_plugin_count: plugin_factory_get_plugin_count,
    get_plugin_descriptor: plugin_factory_get_plugin_descriptor,
    create_plugin: plugin_factory_create_plugin]

## /////////////
##  clap_entry //
## /////////////

proc entry_init*(plugin_path: cstring): bool {.cdecl.} =
  ##  called only once, and very first
  return true

proc entry_deinit*() {.cdecl.} =
  ##  called before unloading the DSO

proc entry_get_factory*(factory_id: cstring): pointer {.cdecl.} =
  if not strcmp(factory_id, CLAP_PLUGIN_FACTORY_ID):
    return addr(s_plugin_factory)
  return nil

##  This symbol will be resolved by the host

## !!!Ignored construct:  CLAP_EXPORT const clap_plugin_entry_t clap_entry = { . clap_version = CLAP_VERSION_INIT , . init = entry_init , . deinit = entry_deinit , . get_factory = entry_get_factory , } ;
## Error: token expected: ; but got: [identifier]!!!
