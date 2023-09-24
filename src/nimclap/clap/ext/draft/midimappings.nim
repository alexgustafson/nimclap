import
  ../../plugin

let CLAP_EXT_MIDI_MAPPINGS*: UncheckedArray[char] = "clap.midi-mappings.draft/0"

const
  CLAP_MIDI_MAPPING_CC7* = 0
  CLAP_MIDI_MAPPING_CC14* = 1
  CLAP_MIDI_MAPPING_RPN* = 2
  CLAP_MIDI_MAPPING_NRPN* = 3

type
  clap_midi_mapping_type* = int32
  clap_midi_mapping* {.bycopy.} = object
    channel*: int32
    number*: int32
    param_id*: clap_id

  clap_plugin_midi_mappings* {.bycopy.} = object
    ##  [main-thread]
    count*: proc (plugin: ptr clap_plugin): uint32 {.cdecl.}
    ##  [main-thread]
    get*: proc (plugin: ptr clap_plugin; index: uint32; mapping: ptr clap_midi_mapping): bool {.
        cdecl.}

  clap_host_midi_mappings* {.bycopy.} = object
    ##  [main-thread]
    changed*: proc (host: ptr clap_host) {.cdecl.}

