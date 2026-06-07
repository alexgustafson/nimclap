import ../../plugin, ../../events, ../../stringsizes, ../../host, ../../id

let extTriggers*: cstring = cstring"clap.triggers/1"

## @page Trigger events
##
## This extension enables the plugin to expose a set of triggers to the host.
##
## Some examples for triggers:
## - trigger an envelope which is independent of the notes
## - trigger a sample-and-hold unit (maybe even per-voice)

const
  triggerIsAutomatablePerNoteId* = 1 shl 0
    ## Does this trigger support per note automations?
  triggerIsAutomatablePerKey* = 1 shl 1
    ## Does this trigger support per key automations?
  triggerIsAutomatablePerChannel* = 1 shl 2
    ## Does this trigger support per channel automations?
  triggerIsAutomatablePerPort* = 1 shl 3
    ## Does this trigger support per port automations?

type TriggerInfoFlags* = uint32

## Given that this extension is still draft, it'll use the event-registry and its own event
## namespace until we stabilize it.
##
## #include <clap/ext/eventregistry.h>
##
## uint16_t CLAP_EXT_TRIGGER_EVENT_SPACE_ID = UINT16_MAX;
## if (host_event_registry->query(host, CLAP_EXT_TRIGGERS, &CLAP_EXT_TRIGGER_EVENT_SPACE_ID)) {
##   /* we can use trigger events */
## }
##
## /* later on */
## clap_event_trigger ev;
## ev.header.space_id = CLAP_EXT_TRIGGER_EVENT_SPACE_ID;
## ev.header.type = CLAP_EVENT_TRIGGER;

const eventTrigger* = 0

type EventTrigger* {.bycopy.} = object
  header*: EventHeader
  triggerId*: Id
    ## target trigger
    ## See `TriggerInfo.id`.
  cookie*: pointer
    ## See `TriggerInfo.cookie`.
  noteId*: int32
    ## target a specific note_id, port, key and channel, -1 for global
  portIndex*: int16
  channel*: int16
  key*: int16

## This describes a trigger

type
  TriggerInfo* {.bycopy.} = object
    ## This describes a trigger.
    id*: Id
      ## stable trigger identifier, it must never change.
    flags*: TriggerInfoFlags
    cookie*: pointer
      ## in analogy to `ParamInfo.cookie`.
    name*: array[name_Size, char]
      ## displayable name
    module*: array[path_Size, char]
      ## the module path containing the trigger, eg:"sequencers/seq1"
      ## '/' will be used as a separator to show a tree like structure.

  PluginTriggers* {.bycopy.} = object
    count*: proc(plugin: ptr Plugin): uint32 {.cdecl.}
      ## Returns the number of triggers.
      ## `[main-thread]`
    getInfo*: proc(
      plugin: ptr Plugin, index: uint32, triggerInfo: ptr TriggerInfo
    ): bool {.cdecl.}
      ## Copies the trigger's info to `triggerInfo` and returns true on success.
      ## `[main-thread]`

const
  triggerRescanInfo* = 1 shl 0
    ## The trigger info did change, use this flag for:
    ## - name change
    ## - module change
    ## New info takes effect immediately.
  triggerRescanAll* = 1 shl 1
    ## Invalidates everything the host knows about triggers.
    ## It can only be used while the plugin is deactivated.
    ## If the plugin is activated use `Host.restart` and delay any change until
    ## the host calls `Plugin.deactivate`.
    ##
    ## You must use this flag if:
    ## - some triggers were added or removed.
    ## - some triggers had critical changes:
    ##   - is_per_note (flag)
    ##   - is_per_key (flag)
    ##   - is_per_channel (flag)
    ##   - is_per_port (flag)
    ##   - cookie

type TriggerRescanFlags* = uint32

const
  triggerClearAll* = 1 shl 0
    ## Clears all possible references to a trigger
  triggerClearAutomations* = 1 shl 1
    ## Clears all automations to a trigger

type
  TriggerClearFlags* = uint32
  HostTriggers* {.bycopy.} = object
    rescan*: proc(host: ptr Host, flags: TriggerRescanFlags) {.cdecl.}
      ## Rescan the full list of triggers according to the flags.
      ## `[main-thread]`
    clear*: proc(host: ptr Host, triggerId: Id, flags: TriggerClearFlags) {.cdecl.}
      ## Clears references to a trigger.
      ## `[main-thread]`
