import version

type Host* {.bycopy.} = object
  ## The host interface handed to the plugin. The plugin uses it to query host
  ## extensions and to make requests back to the host (restart, process, main
  ## thread callbacks, ...).
  clapVersion*: Version
    ## Initialized to `version`: the CLAP version the host was built against.
  hostData*: pointer
    ## Reserved pointer for the host.
  name*: cstring
    ## Mandatory. eg: "Bitwig Studio".
  vendor*: cstring
    ## Mandatory. eg: "Bitwig GmbH".
  url*: cstring
    ## eg: "https://bitwig.com".
  version*: cstring
    ## eg: "4.3". See the `plugin` module for advice on how to format the version.
  getExtension*: proc(host: ptr Host, extensionId: cstring): pointer {.cdecl.}
    ## Query an extension.
    ## The returned pointer is owned by the host.
    ## It is forbidden to call it before `Plugin.init`.
    ## You can call it within the `Plugin.init` call, and after.
    ## `[thread-safe]`
  requestRestart*: proc(host: ptr Host) {.cdecl.}
    ## Request the host to deactivate and then reactivate the plugin.
    ## The operation may be delayed by the host.
    ## `[thread-safe]`
  requestProcess*: proc(host: ptr Host) {.cdecl.}
    ## Request the host to activate and start processing the plugin.
    ## This is useful if you have external IO and need to wake up the plugin from
    ## "sleep".
    ## `[thread-safe]`
  requestCallback*: proc(host: ptr Host) {.cdecl.}
    ## Request the host to schedule a call to `Plugin.onMainThread` on the main
    ## thread.
    ## This callback should be called as soon as practicable, usually in the host
    ## application's next available main thread time slice. Typically callbacks
    ## occur within 33ms / 30hz. Despite this guidance, plugins should not make
    ## assumptions about the exactness of timing for a main thread callback, but
    ## hosts should endeavour to be prompt. For example, in high load situations
    ## the environment may starve the gui/main thread in favor of audio processing,
    ## leading to substantially longer latencies for the callback than the
    ## indicative times given here.
    ## `[thread-safe]`
