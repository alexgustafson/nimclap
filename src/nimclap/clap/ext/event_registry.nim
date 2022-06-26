import
  ../plugin

var CLAP_EXT_EVENT_REGISTRY*: UncheckedArray[char] = "clap.event-registry"

type
  ClapHostEventRegistryT* {.bycopy.} = object
    query*: proc (host: ptr ClapHostT; spaceName: cstring; spaceId: ptr uint16T): bool ##  Queries an event space id.
                                                                            ##  The space id 0 is reserved for CLAP's core events. See CLAP_CORE_EVENT_SPACE.
                                                                            ##
                                                                            ##  Return false and sets *space to UINT16_MAX if the space name is unknown to the host.
                                                                            ##  [main-thread]

