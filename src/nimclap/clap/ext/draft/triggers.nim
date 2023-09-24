import
  ../../plugin, ../../events, ../../stringsizes

let CLAP_EXT_TRIGGERS*: UncheckedArray[char] = "clap.triggers.draft/0"

##  @page Trigger events
##
##  This extension enables the plugin to expose a set of triggers to the host.
##
##  Some examples for triggers:
##  - trigger an envelope which is independent of the notes
##  - trigger a sample-and-hold unit (maybe even per-voice)

const                         ##  Does this trigger support per note automations?
  CLAP_TRIGGER_IS_AUTOMATABLE_PER_NOTE_ID* = 1 shl 0 ##  Does this trigger support per key automations?
  CLAP_TRIGGER_IS_AUTOMATABLE_PER_KEY* = 1 shl 1 ##  Does this trigger support per channel automations?
  CLAP_TRIGGER_IS_AUTOMATABLE_PER_CHANNEL* = 1 shl 2 ##  Does this trigger support per port automations?
  CLAP_TRIGGER_IS_AUTOMATABLE_PER_PORT* = 1 shl 3

type
  clap_trigger_info_flags* = uint32

##  Given that this extension is still draft, it'll use the event-registry and its own event
##  namespace until we stabilize it.
##
##  #include <clap/ext/eventregistry.h>
##
##  uint16_t CLAP_EXT_TRIGGER_EVENT_SPACE_ID = UINT16_MAX;
##  if (host_event_registry->query(host, CLAP_EXT_TRIGGERS, &CLAP_EXT_TRIGGER_EVENT_SPACE_ID)) {
##    /* we can use trigger events */
##  }
##
##  /* later on */
##  clap_event_trigger ev;
##  ev.header.space_id = CLAP_EXT_TRIGGER_EVENT_SPACE_ID;
##  ev.header.type = CLAP_EVENT_TRIGGER;

const
  CLAP_EVENT_TRIGGER* = 0

type
  clap_event_trigger* {.bycopy.} = object
    header*: clap_event_header
    ##  target trigger
    trigger_id*: clap_id
    ##  @ref clap_trigger_info.id
    cookie*: pointer
    ##  @ref clap_trigger_info.cookie
    ##  target a specific note_id, port, key and channel, -1 for global
    note_id*: int32
    port_index*: int16
    channel*: int16
    key*: int16


##  This describes a trigger

type
  clap_trigger_info* {.bycopy.} = object
    ##  stable trigger identifier, it must never change.
    id*: clap_id
    flags*: clap_trigger_info_flags
    ##  in analogy to clap_param_info.cookie
    cookie*: pointer
    ##  displayable name
    name*: array[CLAP_NAME_SIZE, char]
    ##  the module path containing the trigger, eg:"sequencers/seq1"
    ##  '/' will be used as a separator to show a tree like structure.
    module*: array[CLAP_PATH_SIZE, char]

  clap_plugin_triggers* {.bycopy.} = object
    ##  Returns the number of triggers.
    ##  [main-thread]
    count*: proc (plugin: ptr clap_plugin): uint32 {.cdecl.}
    ##  Copies the trigger's info to trigger_info and returns true on success.
    ##  Returns true on success.
    ##  [main-thread]
    get_info*: proc (plugin: ptr clap_plugin; index: uint32;
                   trigger_info: ptr clap_trigger_info): bool {.cdecl.}


const                         ##  The trigger info did change, use this flag for:
     ##  - name change
     ##  - module change
     ##  New info takes effect immediately.
  CLAP_TRIGGER_RESCAN_INFO* = 1 shl 0 ##  Invalidates everything the host knows about triggers.
                                 ##  It can only be used while the plugin is deactivated.
                                 ##  If the plugin is activated use clap_host->restart() and delay any change until the host calls
                                 ##  clap_plugin->deactivate().
                                 ##
                                 ##  You must use this flag if:
                                 ##  - some triggers were added or removed.
                                 ##  - some triggers had critical changes:
                                 ##    - is_per_note (flag)
                                 ##    - is_per_key (flag)
                                 ##    - is_per_channel (flag)
                                 ##    - is_per_port (flag)
                                 ##    - cookie
  CLAP_TRIGGER_RESCAN_ALL* = 1 shl 1

type
  clap_trigger_rescan_flags* = uint32

const                         ##  Clears all possible references to a trigger
  CLAP_TRIGGER_CLEAR_ALL* = 1 shl 0 ##  Clears all automations to a trigger
  CLAP_TRIGGER_CLEAR_AUTOMATIONS* = 1 shl 1

type
  clap_trigger_clear_flags* = uint32
  clap_host_triggers* {.bycopy.} = object
    ##  Rescan the full list of triggers according to the flags.
    ##  [main-thread]
    rescan*: proc (host: ptr clap_host; flags: clap_trigger_rescan_flags) {.cdecl.}
    ##  Clears references to a trigger.
    ##  [main-thread]
    clear*: proc (host: ptr clap_host; trigger_id: clap_id;
                flags: clap_trigger_clear_flags) {.cdecl.}

