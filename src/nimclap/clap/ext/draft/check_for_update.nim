import
  ../../plugin

var CLAP_EXT_CHECK_FOR_UPDATE*: UncheckedArray[char] = "clap.check_for_update.draft/0"

type
  ClapCheckForUpdateInfoT* {.bycopy.} = object
    version*: cstring          ##  latest version
    releaseDate*: cstring      ##  YYYY-MM-DD
    url*: cstring              ##  url to a download page which the user can visit
    isPreview*: bool           ##  true if this version is a preview release

  ClapPluginCheckForUpdate* {.bycopy.} = object
    check*: proc (plugin: ptr ClapPluginT; includePreview: bool) ##  [main-thread]

  ClapHostCheckForUpdateT* {.bycopy.} = object
    onNewVersion*: proc (host: ptr ClapHostT; updateInfo: ptr ClapCheckForUpdateInfoT) ##  [main-thread]

