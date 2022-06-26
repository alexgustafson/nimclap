import
  ../../plugin, ../../string-sizes

##  This extensions provides a set a pages, where each page contains up to 8 controls.
##  Those controls are param_id, and they are meant to be mapped onto a physical controller.
##  We chose 8 because this what most controllers offers, and it is more or less a standard.

var CLAP_EXT_QUICK_CONTROLS*: UncheckedArray[char] = "clap.quick-controls.draft/0"

const
  CLAP_QUICK_CONTROLS_COUNT* = 8

type
  ClapQuickControlsPageT* {.bycopy.} = object
    id*: ClapId
    name*: array[clap_Name_Size, char]
    paramIds*: array[CLAP_QUICK_CONTROLS_COUNT, ClapId]

  ClapPluginQuickControlsT* {.bycopy.} = object
    count*: proc (plugin: ptr ClapPluginT): uint32T ##  [main-thread]
    ##  [main-thread]
    get*: proc (plugin: ptr ClapPluginT; pageIndex: uint32T;
              page: ptr ClapQuickControlsPageT): bool

  ClapHostQuickControlsT* {.bycopy.} = object
    changed*: proc (host: ptr ClapHostT) ##  Informs the host that the quick controls have changed.
                                    ##  [main-thread]
    ##  Suggest a page to the host because it correspond to what the user is currently editing in the
    ##  plugin's GUI.
    ##  [main-thread]
    suggestPage*: proc (host: ptr ClapHostT; pageId: ClapId)

