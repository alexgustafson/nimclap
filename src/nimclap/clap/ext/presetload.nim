import
  ../plugin

let CLAP_EXT_PRESET_LOAD*: cstring = cstring"clap.preset-load/2"

##  The latest draft is 100% compatible.
##  This compat ID may be removed in 2026.

let CLAP_EXT_PRESET_LOAD_COMPAT*: cstring = cstring"clap.preset-load.draft/2"

type
  clap_plugin_preset_load* {.bycopy.} = object
    ##  Loads a preset in the plugin native preset file format from a location.
    ##  The preset discovery provider defines the location and load_key to be passed to this function.
    ##  Returns true on success.
    ##  [main-thread]
    from_location*: proc (plugin: ptr clap_plugin; location_kind: uint32;
                        location: cstring; load_key: cstring): bool {.cdecl.}

  clap_host_preset_load* {.bycopy.} = object
    ##  Called if clap_plugin_preset_load.load() failed.
    ##  os_error: the operating system error, if applicable. If not applicable set it to a non-error
    ##  value, eg: 0 on unix and Windows.
    ##
    ##  [main-thread]
    on_error*: proc (host: ptr clap_host; location_kind: uint32; location: cstring;
                   load_key: cstring; os_error: int32; msg: cstring) {.cdecl.}
    ##  Informs the host that the following preset has been loaded.
    ##  This contributes to keep in sync the host preset browser and plugin preset browser.
    ##  If the preset was loaded from a container file, then the load_key must be set, otherwise it
    ##  must be null.
    ##
    ##  [main-thread]
    loaded*: proc (host: ptr clap_host; location_kind: uint32; location: cstring;
                 load_key: cstring) {.cdecl.}

