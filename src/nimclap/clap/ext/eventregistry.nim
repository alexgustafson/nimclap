import ../plugin, ../host

let extEventRegistry*: cstring = cstring"clap.event-registry"

type HostEventRegistry* {.bycopy.} = object
  query*: proc(host: ptr Host, spaceName: cstring, spaceId: ptr uint16): bool {.cdecl.}
    ## Queries an event space id.
    ## The space id 0 is reserved for CLAP's core events. See `coreEventSpaceId`.
    ##
    ## Return false and sets `spaceId` to `UINT16_MAX` if the space name is unknown
    ## to the host.
    ## `[main-thread]`
