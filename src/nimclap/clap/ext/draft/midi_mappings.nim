import
  ../../plugin

var CLAP_EXT_MIDI_MAPPINGS*: UncheckedArray[char] = "clap.midi-mappings.draft/0"

const
  CLAP_MIDI_MAPPING_CC7* = 0
  CLAP_MIDI_MAPPING_CC14* = 1
  CLAP_MIDI_MAPPING_RPN* = 2
  CLAP_MIDI_MAPPING_NRPN* = 3

type
  ClapMidiMappingType* = int32T
  ClapMidiMappingT* {.bycopy.} = object
    channel*: int32T
    number*: int32T
    paramId*: ClapId

  ClapPluginMidiMappingsT* {.bycopy.} = object
    count*: proc (plugin: ptr ClapPluginT): uint32T ##  [main-thread]
    ##  [main-thread]
    get*: proc (plugin: ptr ClapPluginT; index: uint32T; mapping: ptr ClapMidiMappingT): bool

  ClapHostMidiMappingsT* {.bycopy.} = object
    changed*: proc (host: ptr ClapHostT) ##  [main-thread]

