import
  version

type
  clap_host* {.bycopy.} = object
    clap_version*: clap_version
    ##  initialized to CLAP_VERSION
    host_data*: pointer
    ##  reserved pointer for the host
    ##  name and version are mandatory.
    name*: cstring
    ##  eg: "Bitwig Studio"
    vendor*: cstring
    ##  eg: "Bitwig GmbH"
    url*: cstring
    ##  eg: "https://bitwig.com"
    version*: cstring
    ##  eg: "4.3", see plugin.h for advice on how to format the version
    ##  Query an extension.
    ##  The returned pointer is owned by the host.
    ##  It is forbidden to call it before plugin->init().
    ##  You can call it within plugin->init() call, and after.
    ##  [thread-safe]
    get_extension*: proc (host: ptr clap_host; extension_id: cstring): pointer {.cdecl.}
    ##  Request the host to deactivate and then reactivate the plugin.
    ##  The operation may be delayed by the host.
    ##  [thread-safe]
    request_restart*: proc (host: ptr clap_host) {.cdecl.}
    ##  Request the host to activate and start processing the plugin.
    ##  This is useful if you have external IO and need to wake up the plugin from "sleep".
    ##  [thread-safe]
    request_process*: proc (host: ptr clap_host) {.cdecl.}
    ##  Request the host to schedule a call to plugin->on_main_thread(plugin) on the main thread.
    ##  [thread-safe]
    request_callback*: proc (host: ptr clap_host) {.cdecl.}

