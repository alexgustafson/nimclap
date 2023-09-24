import
  ../../plugin

let CLAP_EXT_CHECK_FOR_UPDATE*: UncheckedArray[char] = "clap.check_for_update.draft/0"

type
  clap_check_for_update_info* {.bycopy.} = object
    version*: cstring
    ##  latest version
    release_date*: cstring
    ##  YYYY-MM-DD
    url*: cstring
    ##  url to a download page which the user can visit
    is_preview*: bool
    ##  true if this version is a preview release

  clap_plugin_check_for_update* {.bycopy.} = object
    ##  [main-thread]
    check*: proc (plugin: ptr clap_plugin; include_preview: bool) {.cdecl.}

  clap_host_check_for_update* {.bycopy.} = object
    ##  [main-thread]
    on_new_version*: proc (host: ptr clap_host;
                         update_info: ptr clap_check_for_update_info) {.cdecl.}

