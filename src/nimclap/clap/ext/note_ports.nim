import
  ../plugin, ../string-sizes

## / @page Note Ports
## /
## / This extension provides a way for the plugin to describe its current note ports.
## / If the plugin does not implement this extension, it won't have note input or output.
## / The plugin is only allowed to change its note ports configuration while it is deactivated.

var CLAP_EXT_NOTE_PORTS*: UncheckedArray[char] = "clap.note-ports"

type
  ClapNoteDialect* = enum       ##  Uses clap_event_note and clap_event_note_expression.
    CLAP_NOTE_DIALECT_CLAP = 1 shl 0, ##  Uses clap_event_midi, no polyphonic expression
    CLAP_NOTE_DIALECT_MIDI = 1 shl 1, ##  Uses clap_event_midi, with polyphonic expression (MPE)
    CLAP_NOTE_DIALECT_MIDI_MPE = 1 shl 2, ##  Uses clap_event_midi2
    CLAP_NOTE_DIALECT_MIDI2 = 1 shl 3


type
  ClapNotePortInfoT* {.bycopy.} = object
    id*: ClapId                ##  stable identifier
    supportedDialects*: uint32T ##  bitfield, see clap_note_dialect
    preferredDialect*: uint32T ##  one value of clap_note_dialect
    name*: array[clap_Name_Size, char] ##  displayable name, i18n?


##  The note ports scan has to be done while the plugin is deactivated.

type
  ClapPluginNotePortsT* {.bycopy.} = object
    count*: proc (plugin: ptr ClapPluginT; isInput: bool): uint32T ##  number of ports, for either input or output
                                                           ##  [main-thread]
    ##  get info about about a note port.
    ##  [main-thread]
    get*: proc (plugin: ptr ClapPluginT; index: uint32T; isInput: bool;
              info: ptr ClapNotePortInfoT): bool


const ##  The ports have changed, the host shall perform a full scan of the ports.
     ##  This flag can only be used if the plugin is not active.
     ##  If the plugin active, call host->request_restart() and then call rescan()
     ##  when the host calls deactivate()
  CLAP_NOTE_PORTS_RESCAN_ALL* = 1 shl 0 ##  The ports name did change, the host can scan them right away.
  CLAP_NOTE_PORTS_RESCAN_NAMES* = 1 shl 1

type
  ClapHostNotePortsT* {.bycopy.} = object
    supportedDialects*: proc (host: ptr ClapHostT): uint32T ##  Query which dialects the host supports
                                                      ##  [main-thread]
    ##  Rescan the full list of note ports according to the flags.
    ##  [main-thread]
    rescan*: proc (host: ptr ClapHostT; flags: uint32T)

