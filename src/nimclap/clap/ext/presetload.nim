import ../plugin, ../host

let extPresetLoad*: cstring = cstring"clap.preset-load/2"

let extPresetLoadCompat*: cstring = cstring"clap.preset-load.draft/2"
  ## The latest draft is 100% compatible.
  ## This compat ID may be removed in 2026.

type
  PluginPresetLoad* {.bycopy.} = object
    fromLocation*: proc(
      plugin: ptr Plugin, locationKind: uint32, location: cstring, loadKey: cstring
    ): bool {.cdecl.}
      ## Loads a preset in the plugin native preset file format from a location.
      ## The preset discovery provider defines the location and `loadKey` to be
      ## passed to this function.
      ## Returns true on success.
      ## `[main-thread]`

  HostPresetLoad* {.bycopy.} = object
    onError*: proc(
      host: ptr Host,
      locationKind: uint32,
      location: cstring,
      loadKey: cstring,
      osError: int32,
      msg: cstring,
    ) {.cdecl.}
      ## Called if `PluginPresetLoad.load` failed.
      ## `osError`: the operating system error, if applicable. If not applicable
      ## set it to a non-error value, eg: 0 on unix and Windows.
      ##
      ## `[main-thread]`
    loaded*: proc(
      host: ptr Host, locationKind: uint32, location: cstring, loadKey: cstring
    ) {.cdecl.}
      ## Informs the host that the following preset has been loaded.
      ## This contributes to keep in sync the host preset browser and plugin
      ## preset browser.
      ## If the preset was loaded from a container file, then the `loadKey` must
      ## be set, otherwise it must be null.
      ##
      ## `[main-thread]`
