import
  ../plugin

var CLAP_EXT_TAIL*: UncheckedArray[char] = "clap.tail"

type
  ClapPluginTailT* {.bycopy.} = object
    get*: proc (plugin: ptr ClapPluginT): uint32T ##  Returns tail length in samples.
                                            ##  Any value greater or equal to INT32_MAX implies infinite tail.
                                            ##  [main-thread,audio-thread]

  ClapHostTailT* {.bycopy.} = object
    changed*: proc (host: ptr ClapHostT) ##  Tell the host that the tail has changed.
                                    ##  [audio-thread]

