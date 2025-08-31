import ../id, ../host
import ../plugin, ../stringsizes

##  @page Note Ports
##
##  This extension provides a way for the plugin to describe its current note ports.
##  If the plugin does not implement this extension, it won't have note input or output.
##  The plugin is only allowed to change its note ports configuration while it is deactivated.

let extNotePorts*: cstring = cstring"clap.note-ports"

type NoteDialect* {.pure.} = enum ##  Uses clap_event_note and clap_event_note_expression.
  dialectClap = 1 shl 0 ##  Uses clap_event_midi, no polyphonic expression
  dialectMidi = 1 shl 1 ##  Uses clap_event_midi, with polyphonic expression (MPE)
  dialectMidiMpe = 1 shl 2 ##  Uses clap_event_midi2
  dialectMidi2 = 1 shl 3

type NotePortInfo* {.bycopy.} = object
  ##  id identifies a port and must be stable.
  ##  id may overlap between input and output ports.
  id*: Id
  supportedDialects*: uint32
  ##  bitfield, see clap_note_dialect
  preferredDialect*: uint32
  ##  one value of clap_note_dialect
  name*: array[name_Size, char] ##  displayable name, i18n?

##  The note ports scan has to be done while the plugin is deactivated.

type PluginNotePorts* {.bycopy.} = object
  ##  Number of ports, for either input or output.
  ##  [main-thread]
  count*: proc(plugin: ptr Plugin, isInput: bool): uint32 {.cdecl.}
  ##  Get info about a note port.
  ##  Returns true on success and stores the result into info.
  ##  [main-thread]
  get*: proc(
    plugin: ptr Plugin, index: uint32, isInput: bool, info: ptr NotePortInfo
  ): bool {.cdecl.}

const
  ##  The ports have changed, the host shall perform a full scan of the ports.
  ##  This flag can only be used if the plugin is not active.
  ##  If the plugin active, call host->request_restart() and then call rescan()
  ##  when the host calls deactivate()
  notePortsRescanAll* = 1 shl 0
    ##  The ports name did change, the host can scan them right away.
  notePortsRescanNames* = 1 shl 1

type HostNotePorts* {.bycopy.} = object
  ##  Query which dialects the host supports
  ##  [main-thread]
  supportedDialects*: proc(host: ptr Host): uint32 {.cdecl.}
  ##  Rescan the full list of note ports according to the flags.
  ##  [main-thread]
  rescan*: proc(host: ptr Host, flags: uint32) {.cdecl.}
