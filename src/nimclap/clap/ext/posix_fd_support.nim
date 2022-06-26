import
  ../plugin

##  This extension let your plugin hook itself into the host select/poll/epoll/kqueue reactor.
##  This is useful to handle asynchronous I/O on the main thread.

var CLAP_EXT_POSIX_FD_SUPPORT*: UncheckedArray[char] = "clap.posix-fd-support"

const ##  IO events flags, they can be used to form a mask which describes:
     ##  - which events you are interested in (register_fd/modify_fd)
     ##  - which events happened (on_fd)
  CLAP_POSIX_FD_READ* = 1 shl 0
  CLAP_POSIX_FD_WRITE* = 1 shl 1
  CLAP_POSIX_FD_ERROR* = 1 shl 2

type
  ClapPosixFdFlagsT* = uint32T
  ClapPluginPosixFdSupportT* {.bycopy.} = object
    onFd*: proc (plugin: ptr ClapPluginT; fd: cint; flags: ClapPosixFdFlagsT) ##  This callback is "level-triggered".
                                                                     ##  It means that a writable fd will continuously produce "on_fd()" events;
                                                                     ##  don't forget using modify_fd() to remove the write notification once you're
                                                                     ##  done writting.
                                                                     ##
                                                                     ##  [main-thread]

  ClapHostPosixFdSupportT* {.bycopy.} = object
    registerFd*: proc (host: ptr ClapHostT; fd: cint; flags: ClapPosixFdFlagsT): bool ##  [main-thread]
    ##  [main-thread]
    modifyFd*: proc (host: ptr ClapHostT; fd: cint; flags: ClapPosixFdFlagsT): bool ##  [main-thread]
    unregisterFd*: proc (host: ptr ClapHostT; fd: cint): bool

