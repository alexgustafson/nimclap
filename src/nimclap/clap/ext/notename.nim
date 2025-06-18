import
  ../plugin, ../stringsizes

let CLAP_EXT_NOTE_NAME*: cstring = cstring"clap.note-name"

type
  clap_note_name* {.bycopy.} = object
    name*: array[CLAP_NAME_SIZE, char]
    ##  -1 for every port
    port*: int16
    ##  -1 for every key
    key*: int16
    ##  -1 for every channel
    channel*: int16

  clap_plugin_note_name* {.bycopy.} = object
    ##  Return the number of note names
    ##  [main-thread]
    count*: proc (plugin: ptr clap_plugin): uint32 {.cdecl.}
    ##  Returns true on success and stores the result into note_name
    ##  [main-thread]
    get*: proc (plugin: ptr clap_plugin; index: uint32; note_name: ptr clap_note_name): bool {.
        cdecl.}

  clap_host_note_name* {.bycopy.} = object
    ##  Informs the host that the note names have changed.
    ##  [main-thread]
    changed*: proc (host: ptr clap_host) {.cdecl.}

