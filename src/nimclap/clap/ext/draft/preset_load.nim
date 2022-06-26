import
  ../../plugin

var CLAP_EXT_PRESET_LOAD*: UncheckedArray[char] = "clap.preset-load.draft/0"

type
  ClapPluginPresetLoadT* {.bycopy.} = object
    fromFile*: proc (plugin: ptr ClapPluginT; path: cstring): bool ##  Loads a preset in the plugin native preset file format from a path.
                                                           ##  [main-thread]

