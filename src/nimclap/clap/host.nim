import
  version

type
  ClapHostT* {.bycopy.} = object
    clapVersion*: ClapVersionT ##  initialized to CLAP_VERSION
    hostData*: pointer         ##  reserved pointer for the host
                     ##  name and version are mandatory.
    name*: cstring             ##  eg: "Bitwig Studio"
    vendor*: cstring           ##  eg: "Bitwig GmbH"
    url*: cstring              ##  eg: "https://bitwig.com"
    version*: cstring          ##  eg: "4.3"
                    ##  Query an extension.
                    ##  [thread-safe]
    getExtension*: proc (host: ptr ClapHost; extensionId: cstring): pointer ##  Request the host to deactivate and then reactivate the plugin.
                                                                    ##  The operation may be delayed by the host.
                                                                    ##  [thread-safe]
    requestRestart*: proc (host: ptr ClapHost) ##  Request the host to activate and start processing the plugin.
                                          ##  This is useful if you have external IO and need to wake up the plugin from "sleep".
                                          ##  [thread-safe]
    requestProcess*: proc (host: ptr ClapHost) ##  Request the host to schedule a call to plugin->on_main_thread(plugin) on the main thread.
                                          ##  [thread-safe]
    requestCallback*: proc (host: ptr ClapHost)

