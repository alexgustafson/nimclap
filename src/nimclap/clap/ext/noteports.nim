import ../id, ../host
import ../plugin, ../stringsizes

## @page Note Ports
##
## This extension provides a way for the plugin to describe its current note ports.
## If the plugin does not implement this extension, it won't have note input or output.
## The plugin is only allowed to change its note ports configuration while it is deactivated.

let extNotePorts*: cstring = cstring"clap.note-ports"

type NoteDialect* {.pure.} = enum
  dialectClap = 1 shl 0
    ## Uses `EventNote` and `EventNoteExpression`.
  dialectMidi = 1 shl 1
    ## Uses `EventMidi`, no polyphonic expression.
  dialectMidiMpe = 1 shl 2
    ## Uses `EventMidi`, with polyphonic expression (MPE).
  dialectMidi2 = 1 shl 3
    ## Uses `EventMidi2`.

type NotePortInfo* {.bycopy.} = object
  id*: Id
    ## `id` identifies a port and must be stable.
    ## `id` may overlap between input and output ports.
  supportedDialects*: uint32
    ## Bitfield, see `NoteDialect`.
  preferredDialect*: uint32
    ## One value of `NoteDialect`.
  name*: array[name_Size, char]
    ## Displayable name, i18n?

type PluginNotePorts* {.bycopy.} = object
  ## The note ports scan has to be done while the plugin is deactivated.
  count*: proc(plugin: ptr Plugin, isInput: bool): uint32 {.cdecl.}
    ## Number of ports, for either input or output.
    ## `[main-thread]`
  get*: proc(
    plugin: ptr Plugin, index: uint32, isInput: bool, info: ptr NotePortInfo
  ): bool {.cdecl.}
    ## Get info about a note port.
    ## Returns true on success and stores the result into `info`.
    ## `[main-thread]`

const
  notePortsRescanAll* = 1 shl 0
    ## The ports have changed, the host shall perform a full scan of the ports.
    ## This flag can only be used if the plugin is not active.
    ## If the plugin active, call `Host.requestRestart` and then call `rescan`
    ## when the host calls `deactivate`.
  notePortsRescanNames* = 1 shl 1
    ## The ports name did change, the host can scan them right away.

type HostNotePorts* {.bycopy.} = object
  supportedDialects*: proc(host: ptr Host): uint32 {.cdecl.}
    ## Query which dialects the host supports.
    ## `[main-thread]`
  rescan*: proc(host: ptr Host, flags: uint32) {.cdecl.}
    ## Rescan the full list of note ports according to the flags.
    ## `[main-thread]`
