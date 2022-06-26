import
  ../plugin, ../string-sizes

var CLAP_EXT_NOTE_NAME*: UncheckedArray[char] = "clap.note-name"

type
  ClapNoteNameT* {.bycopy.} = object
    name*: array[clap_Name_Size, char]
    port*: int16T              ##  -1 for every port
    key*: int16T               ##  -1 for every key
    channel*: int16T           ##  -1 for every channel

  ClapPluginNoteName* {.bycopy.} = object
    count*: proc (plugin: ptr ClapPluginT): uint32T ##  Return the number of note names
                                              ##  [main-thread]
    ##  Returns true on success and stores the result into note_name
    ##  [main-thread]
    get*: proc (plugin: ptr ClapPluginT; index: uint32T; noteName: ptr ClapNoteNameT): bool

  ClapHostNoteNameT* {.bycopy.} = object
    changed*: proc (host: ptr ClapHostT) ##  Informs the host that the note names has changed.
                                    ##  [main-thread]

