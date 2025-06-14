import
  ../../plugin, ../../stream

let CLAP_EXT_UNDO*: cstring = cstring"clap.undo/4"

let CLAP_EXT_UNDO_CONTEXT*: cstring = cstring"clap.undo_context/4"

let CLAP_EXT_UNDO_DELTA*: cstring = cstring"clap.undo_delta/4"

##  @page Undo
##
##  This extension enables the plugin to merge its undo history with the host.
##  This leads to a single undo history shared by the host and many plugins.
##
##  Calling host->undo() or host->redo() is equivalent to clicking undo/redo within the host's GUI.
##
##  If the plugin uses this interface then its undo and redo should be entirely delegated to
##  the host; clicking in the plugin's UI undo or redo is equivalent to clicking undo or redo in the
##  host's UI.
##
##  Some changes are long running changes, for example a mouse interaction will begin editing some
##  complex data and it may take multiple events and a long duration to complete the change.
##  In such case the plugin will call host->begin_change() to indicate the beginning of a long
##  running change and complete the change by calling host->change_made().
##
##  The host may group changes together:
##  [---------------------------------]
##  ^-T0      ^-T1    ^-T2            ^-T3
##  Here a long running change C0 begin at T0.
##  A instantaneous change C1 at T1, and another one C2 at T2.
##  Then at T3 the long running change is completed.
##  The host will then create a single undo step that will merge all the changes into C0.
##
##  This leads to another important consideration: starting a long running change without
##  terminating is **VERY BAD**, because while a change is running it is impossible to call undo or
##  redo.
##
##  Rationale: multiple designs were considered and this one has the benefit of having a single undo
##  history. This simplifies the host implementation, leading to less bugs, a more robust design
##  and maybe an easier experience for the user because there's a single undo context versus one
##  for the host and one for each plugin instance.
##
##  This extension tries to make it as easy as possible for the plugin to hook into the host undo
##  and make it efficient when possible by using deltas. The plugin interfaces are all optional, and
##  the plugin can for a minimal implementation, just use the host interface and call
##  host->change_made() without providing a delta. This is enough for the host to know that it can
##  capture a plugin state for the undo step.

type
  clap_undo_delta_properties* {.bycopy.} = object
    ##  If true, then the plugin will provide deltas in host->change_made().
    ##  If false, then all clap_undo_delta_properties's attributes become irrelevant.
    has_delta*: bool
    ##  If true, then the deltas can be stored on disk and re-used in the future as long as the plugin
    ##  is compatible with the given format_version.
    ##
    ##  If false, then format_version must be set to CLAP_INVALID_ID.
    are_deltas_persistent*: bool
    ##  This represents the delta format version that the plugin is currently using.
    ##  Use CLAP_INVALID_ID for invalid value.
    format_version*: clap_id


##  Use CLAP_EXT_UNDO_DELTA.
##  This is an optional interface, using deltas is an optimization versus making a state snapshot.

type
  clap_plugin_undo_delta* {.bycopy.} = object
    ##  Asks the plugin the delta properties.
    ##  [main-thread]
    get_delta_properties*: proc (plugin: ptr clap_plugin;
                               properties: ptr clap_undo_delta_properties) {.cdecl.}
    ##  Asks the plugin if it can apply a delta using the given format version.
    ##  Returns true if it is possible.
    ##  [main-thread]
    can_use_delta_format_version*: proc (plugin: ptr clap_plugin;
                                       format_version: clap_id): bool {.cdecl.}
    ##  Undo using the delta.
    ##  Returns true on success.
    ##
    ##  [main-thread]
    undo*: proc (plugin: ptr clap_plugin; format_version: clap_id; delta: pointer;
               delta_size: csize): bool {.cdecl.}
    ##  Redo using the delta.
    ##  Returns true on success.
    ##
    ##  [main-thread]
    redo*: proc (plugin: ptr clap_plugin; format_version: clap_id; delta: pointer;
               delta_size: csize): bool {.cdecl.}


##  Use CLAP_EXT_UNDO_CONTEXT.
##  This is an optional interface, that the plugin can implement in order to know about
##  the current undo context.

type
  clap_plugin_undo_context* {.bycopy.} = object
    ##  Indicate if it is currently possible to perform an undo or redo operation.
    ##  [main-thread & plugin-subscribed-to-undo-context]
    set_can_undo*: proc (plugin: ptr clap_plugin; can_undo: bool) {.cdecl.}
    set_can_redo*: proc (plugin: ptr clap_plugin; can_redo: bool) {.cdecl.}
    ##  Sets the name of the next undo or redo step.
    ##  name: null terminated string.
    ##  [main-thread & plugin-subscribed-to-undo-context]
    set_undo_name*: proc (plugin: ptr clap_plugin; name: cstring) {.cdecl.}
    set_redo_name*: proc (plugin: ptr clap_plugin; name: cstring) {.cdecl.}


##  Use CLAP_EXT_UNDO.

type
  clap_host_undo* {.bycopy.} = object
    ##  Begins a long running change.
    ##  The plugin must not call this twice: there must be either a call to cancel_change() or
    ##  change_made() before calling begin_change() again.
    ##  [main-thread]
    begin_change*: proc (host: ptr clap_host) {.cdecl.}
    ##  Cancels a long running change.
    ##  cancel_change() must not be called without a preceding begin_change().
    ##  [main-thread]
    cancel_change*: proc (host: ptr clap_host) {.cdecl.}
    ##  Completes an undoable change.
    ##  At the moment of this function call, plugin_state->save() would include the current change.
    ##
    ##  name: mandatory null terminated string describing the change, this is displayed to the user
    ##
    ##  delta: optional, it is a binary blobs used to perform the undo and redo. When not available
    ##  the host will save the plugin state and use state->load() to perform undo and redo.
    ##  The plugin must be able to perform a redo operation using the delta, though the undo operation
    ##  is only possible if delta_can_undo is true.
    ##
    ##  Note: the provided delta may be used for incremental state saving and crash recovery. The
    ##  plugin can indicate a format version id and the validity lifetime for the binary blobs.
    ##  The host can use these to verify the compatibility before applying the delta.
    ##  If the plugin is unable to use a delta, a notification should be provided to the user and
    ##  the crash recovery should perform a best effort job, at least restoring the latest saved
    ##  state.
    ##
    ##  Special case: for objects with shared and synchronized state, changes shouldn't be reported
    ##  as the host already knows about it.
    ##  For example, plugin parameter changes shouldn't produce a call to change_made().
    ##
    ##  Note: if the plugin asked for this interface, then host_state->mark_dirty() will not create an
    ##  implicit undo step.
    ##
    ##  Note: if the plugin did load a preset or did something that leads to a large delta,
    ##  it may consider not producing a delta (pass null) and let the host make a state snapshot
    ##  instead.
    ##
    ##  Note: if a plugin is producing a lot of changes within a small amount of time, the host
    ##  may merge them into a single undo step.
    ##
    ##  [main-thread]
    change_made*: proc (host: ptr clap_host; name: cstring; delta: pointer;
                      delta_size: csize; delta_can_undo: bool) {.cdecl.}
    ##  Asks the host to perform the next undo or redo step.
    ##
    ##  Note: this maybe a complex and asynchronous operation, which may complete after
    ##  this function returns.
    ##
    ##  Note: the host may ignore this request if there is no undo/redo step to perform,
    ##  or if the host is unable to perform undo/redo at the time (eg: a long running
    ##  change is going on).
    ##
    ##  [main-thread]
    request_undo*: proc (host: ptr clap_host) {.cdecl.}
    request_redo*: proc (host: ptr clap_host) {.cdecl.}
    ##  Subscribes to or unsubscribes from undo context info.
    ##
    ##  This method helps reducing the number of calls the host has to perform when updating
    ##  the undo context info. Consider a large project with 1000+ plugins, we don't want to
    ##  call 1000+ times update, while the plugin may only need the context info if its GUI
    ##  is shown and it wants to display undo/redo info.
    ##
    ##  Initial state is unsubscribed.
    ##
    ##  is_subscribed: set to true to receive context info
    ##
    ##  It is mandatory for the plugin to implement CLAP_EXT_UNDO_CONTEXT when using this method.
    ##
    ##  [main-thread]
    set_wants_context_updates*: proc (host: ptr clap_host; is_subscribed: bool) {.cdecl.}

