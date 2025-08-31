import ../plugin

let extEventRegistry*: cstring = cstring"clap.event-registry"

type HostEventRegistry* {.bycopy.} = object
  ##  Queries an event space id.
  ##  The space id 0 is reserved for CLAP's core events. See CLAP_CORE_EVENT_SPACE.
  ##
  ##  Return false and sets *space_id to UINT16_MAX if the space name is unknown to the host.
  ##  [main-thread]
  query*: proc(host: ptr Host, spaceName: cstring, spaceId: ptr uint16): bool {.cdecl.}
