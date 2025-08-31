import ../plugin

let extTail*: cstring = cstring"clap.tail"

type
  PluginTail* {.bycopy.} = object
    ##  Returns tail length in samples.
    ##  Any value greater or equal to INT32_MAX implies infinite tail.
    ##  [main-thread,audio-thread]
    get*: proc(plugin: ptr Plugin): uint32 {.cdecl.}

  HostTail* {.bycopy.} = object
    ##  Tell the host that the tail has changed.
    ##  [audio-thread]
    changed*: proc(host: ptr Host) {.cdecl.}
