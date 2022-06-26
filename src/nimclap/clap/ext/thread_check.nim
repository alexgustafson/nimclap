import
  ../plugin

var CLAP_EXT_THREAD_CHECK*: UncheckedArray[char] = "clap.thread-check"

##  This interface is useful to do runtime checks and make
##  sure that the functions are called on the correct threads.
##  It is highly recommended to implement this extension

type
  ClapHostThreadCheckT* {.bycopy.} = object
    isMainThread*: proc (host: ptr ClapHostT): bool ##  Returns true if "this" thread is the main thread.
                                              ##  [thread-safe]
    ##  Returns true if "this" thread is one of the audio threads.
    ##  [thread-safe]
    isAudioThread*: proc (host: ptr ClapHostT): bool

