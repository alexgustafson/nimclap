import ../plugin, ../host

let extTail*: cstring = cstring"clap.tail"

type
  PluginTail* {.bycopy.} = object
    get*: proc(plugin: ptr Plugin): uint32 {.cdecl.}
      ## Returns tail length in samples.
      ## Any value greater or equal to `INT32_MAX` implies infinite tail.
      ## `[main-thread,audio-thread]`

  HostTail* {.bycopy.} = object
    changed*: proc(host: ptr Host) {.cdecl.}
      ## Tell the host that the tail has changed.
      ## `[audio-thread]`
