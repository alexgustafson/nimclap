import ../plugin, ../host

## This extension let your plugin hook itself into the host select/poll/epoll/kqueue reactor.
## This is useful to handle asynchronous I/O on the main thread.

let extPosixFdSupport*: cstring = cstring"clap.posix-fd-support"

const
  posixFdRead* = 1 shl 0
    ## IO events flags, they can be used to form a mask which describes:
    ## - which events you are interested in (`registerFd`/`modifyFd`)
    ## - which events happened (`onFd`)
  posixFdWrite* = 1 shl 1
  posixFdError* = 1 shl 2

type
  PosixFdFlags* = uint32
  PluginPosixFdSupport* {.bycopy.} = object
    onFd*: proc(plugin: ptr Plugin, fd: cint, flags: PosixFdFlags) {.cdecl.}
      ## This callback is "level-triggered".
      ## It means that a writable fd will continuously produce `onFd` events;
      ## don't forget using `modifyFd` to remove the write notification once
      ## you're done writing.
      ##
      ## `[main-thread]`

  HostPosixFdSupport* {.bycopy.} = object
    registerFd*: proc(host: ptr Host, fd: cint, flags: PosixFdFlags): bool {.cdecl.}
      ## Returns true on success.
      ## `[main-thread]`
    modifyFd*: proc(host: ptr Host, fd: cint, flags: PosixFdFlags): bool {.cdecl.}
      ## Returns true on success.
      ## `[main-thread]`
    unregisterFd*: proc(host: ptr Host, fd: cint): bool {.cdecl.}
      ## Returns true on success.
      ## `[main-thread]`
