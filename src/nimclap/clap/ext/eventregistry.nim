import
  ../plugin

let CLAP_EXT_EVENT_REGISTRY*: cstring = cstring"clap.event-registry"

type
  clap_host_event_registry* {.bycopy.} = object
    ##  Queries an event space id.
    ##  The space id 0 is reserved for CLAP's core events. See CLAP_CORE_EVENT_SPACE.
    ##
    ##  Return false and sets *space_id to UINT16_MAX if the space name is unknown to the host.
    ##  [main-thread]
    query*: proc (host: ptr clap_host; space_name: cstring; space_id: ptr uint16): bool {.
        cdecl.}

