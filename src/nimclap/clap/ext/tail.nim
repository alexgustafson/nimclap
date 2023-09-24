import
  ../plugin

let CLAP_EXT_TAIL*: UncheckedArray[char] = "clap.tail"

type
  clap_plugin_tail* {.bycopy.} = object
    ##  Returns tail length in samples.
    ##  Any value greater or equal to INT32_MAX implies infinite tail.
    ##  [main-thread,audio-thread]
    get*: proc (plugin: ptr clap_plugin): uint32 {.cdecl.}

  clap_host_tail* {.bycopy.} = object
    ##  Tell the host that the tail has changed.
    ##  [audio-thread]
    changed*: proc (host: ptr clap_host) {.cdecl.}

