import ../plugin, ../stringsizes, ../host

let extNoteName*: cstring = cstring"clap.note-name"

type
  NoteName* {.bycopy.} = object
    name*: array[name_Size, char]
    port*: int16
      ## -1 for every port.
    key*: int16
      ## -1 for every key.
    channel*: int16
      ## -1 for every channel.

  PluginNoteName* {.bycopy.} = object
    count*: proc(plugin: ptr Plugin): uint32 {.cdecl.}
      ## Return the number of note names.
      ## `[main-thread]`
    get*:
      proc(plugin: ptr Plugin, index: uint32, noteName: ptr NoteName): bool {.cdecl.}
      ## Returns true on success and stores the result into `noteName`.
      ## `[main-thread]`

  HostNoteName* {.bycopy.} = object
    changed*: proc(host: ptr Host) {.cdecl.}
      ## Informs the host that the note names have changed.
      ## `[main-thread]`
