import ../plugin, ../stringsizes

let extNoteName*: cstring = cstring"clap.note-name"

type
  NoteName* {.bycopy.} = object
    name*: array[name_Size, char]
    port*: int16
    ##  -1 for every port
    key*: int16
    ##  -1 for every key
    channel*: int16 ##  -1 for every channel

  PluginNoteName* {.bycopy.} = object
    ##  Return the number of note names
    ##  [main-thread]
    count*: proc(plugin: ptr Plugin): uint32 {.cdecl.}
    ##  Returns true on success and stores the result into note_name
    ##  [main-thread]
    get*:
      proc(plugin: ptr Plugin, index: uint32, noteName: ptr NoteName): bool {.cdecl.}

  HostNoteName* {.bycopy.} = object
    ##  Informs the host that the note names have changed.
    ##  [main-thread]
    changed*: proc(host: ptr Host) {.cdecl.}
