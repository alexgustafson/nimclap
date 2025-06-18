import
  version

type
  clap_host* {.bycopy.} = object
    ##  initialized to CLAP_VERSION
    clap_version*: clap_version
    ##  reserved pointer for the host
    host_data*: pointer
    ##  name and version are mandatory.
    ##  eg: "Bitwig Studio"
    name*: cstring
    ##  eg: "Bitwig GmbH"
    vendor*: cstring
    ##  eg: "https://bitwig.com"
    url*: cstring
    ##  eg: "4.3", see plugin.h for advice on how to format the version
    version*: cstring
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
    ##  This callback should be called as soon as practicable, usually in the host application's next
    ##  available main thread time slice. Typically callbacks occur within 33ms / 30hz.
    ##  Despite this guidance, plugins should not make assumptions about the exactness of timing for
    ##  a main thread callback, but hosts should endeavour to be prompt. For example, in high load
    ##  situations the environment may starve the gui/main thread in favor of audio processing,
    ##  leading to substantially longer latencies for the callback than the indicative times given
    ##  here.
    ##  [thread-safe]
    request_callback*: proc (host: ptr clap_host) {.cdecl.}

