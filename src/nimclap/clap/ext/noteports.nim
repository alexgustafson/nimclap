import ../id, ../host
import
  ../plugin, ../stringsizes

##  @page Note Ports
##
##  This extension provides a way for the plugin to describe its current note ports.
##  If the plugin does not implement this extension, it won't have note input or output.
##  The plugin is only allowed to change its note ports configuration while it is deactivated.

let CLAP_EXT_NOTE_PORTS*: cstring = cstring"clap.note-ports"

type
  clap_note_dialect* = enum     ##  Uses clap_event_note and clap_event_note_expression.
    CLAP_NOTE_DIALECT_CLAP = 1 shl 0, ##  Uses clap_event_midi, no polyphonic expression
    CLAP_NOTE_DIALECT_MIDI = 1 shl 1, ##  Uses clap_event_midi, with polyphonic expression (MPE)
    CLAP_NOTE_DIALECT_MIDI_MPE = 1 shl 2, ##  Uses clap_event_midi2
    CLAP_NOTE_DIALECT_MIDI2 = 1 shl 3


type
  clap_note_port_info* {.bycopy.} = object
    ##  id identifies a port and must be stable.
    ##  id may overlap between input and output ports.
    id*: clap_id
    ##  bitfield, see clap_note_dialect
    supported_dialects*: uint32
    ##  one value of clap_note_dialect
    preferred_dialect*: uint32
    ##  displayable name, i18n?
    name*: array[CLAP_NAME_SIZE, char]


##  The note ports scan has to be done while the plugin is deactivated.

type
  clap_plugin_note_ports* {.bycopy.} = object
    ##  Number of ports, for either input or output.
    ##  [main-thread]
    count*: proc (plugin: ptr clap_plugin; is_input: bool): uint32 {.cdecl.}
    ##  Get info about a note port.
    ##  Returns true on success and stores the result into info.
    ##  [main-thread]
    get*: proc (plugin: ptr clap_plugin; index: uint32; is_input: bool;
              info: ptr clap_note_port_info): bool {.cdecl.}


const ##  The ports have changed, the host shall perform a full scan of the ports.
     ##  This flag can only be used if the plugin is not active.
     ##  If the plugin active, call host->request_restart() and then call rescan()
     ##  when the host calls deactivate()
  CLAP_NOTE_PORTS_RESCAN_ALL* = 1 shl 0 ##  The ports name did change, the host can scan them right away.
  CLAP_NOTE_PORTS_RESCAN_NAMES* = 1 shl 1

type
  clap_host_note_ports* {.bycopy.} = object
    ##  Query which dialects the host supports
    ##  [main-thread]
    supported_dialects*: proc (host: ptr clap_host): uint32 {.cdecl.}
    ##  Rescan the full list of note ports according to the flags.
    ##  [main-thread]
    rescan*: proc (host: ptr clap_host; flags: uint32) {.cdecl.}

