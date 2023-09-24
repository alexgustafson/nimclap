import
  ../plugin

##  This extension let your plugin hook itself into the host select/poll/epoll/kqueue reactor.
##  This is useful to handle asynchronous I/O on the main thread.

let CLAP_EXT_POSIX_FD_SUPPORT*: UncheckedArray[char] = "clap.posix-fd-support"

const ##  IO events flags, they can be used to form a mask which describes:
     ##  - which events you are interested in (register_fd/modify_fd)
     ##  - which events happened (on_fd)
  CLAP_POSIX_FD_READ* = 1 shl 0
  CLAP_POSIX_FD_WRITE* = 1 shl 1
  CLAP_POSIX_FD_ERROR* = 1 shl 2

type
  clap_posix_fd_flags* = uint32
  clap_plugin_posix_fd_support* {.bycopy.} = object
    ##  This callback is "level-triggered".
    ##  It means that a writable fd will continuously produce "on_fd()" events;
    ##  don't forget using modify_fd() to remove the write notification once you're
    ##  done writing.
    ##
    ##  [main-thread]
    on_fd*: proc (plugin: ptr clap_plugin; fd: cint; flags: clap_posix_fd_flags) {.cdecl.}

  clap_host_posix_fd_support* {.bycopy.} = object
    ##  [main-thread]
    register_fd*: proc (host: ptr clap_host; fd: cint; flags: clap_posix_fd_flags): bool {.
        cdecl.}
    ##  [main-thread]
    modify_fd*: proc (host: ptr clap_host; fd: cint; flags: clap_posix_fd_flags): bool {.
        cdecl.}
    ##  [main-thread]
    unregister_fd*: proc (host: ptr clap_host; fd: cint): bool {.cdecl.}

