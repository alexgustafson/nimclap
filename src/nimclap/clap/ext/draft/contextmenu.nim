import
  ../../plugin

##  This extension lets the host and plugin exchange menu items and let the plugin ask the host to
##  show its context menu.

let CLAP_EXT_CONTEXT_MENU*: cstring = cstring"clap.context-menu.draft/0"

##  There can be different target kind for a context menu

const
  CLAP_CONTEXT_MENU_TARGET_KIND_GLOBAL* = 0
  CLAP_CONTEXT_MENU_TARGET_KIND_PARAM* = 1 ##  TODO: kind trigger once the trigger ext is marked as stable

##  Describes the context menu target

type
  clap_context_menu_target* {.bycopy.} = object
    kind*: uint32
    id*: clap_id


const                         ##  Adds a clickable menu entry.
     ##  data: const clap_context_menu_item_entry_t*
  CLAP_CONTEXT_MENU_ITEM_ENTRY* = 0 ##  Adds a clickable menu entry which will feature both a checkmark and a label.
                                 ##  data: const clap_context_menu_item_check_entry_t*
  CLAP_CONTEXT_MENU_ITEM_CHECK_ENTRY* = 1 ##  Adds a separator line.
                                       ##  data: NULL
  CLAP_CONTEXT_MENU_ITEM_SEPARATOR* = 2 ##  Starts a sub menu with the given label.
                                     ##  data: const clap_context_menu_item_begin_submenu_t*
  CLAP_CONTEXT_MENU_ITEM_BEGIN_SUBMENU* = 3 ##  Ends the current sub menu.
                                         ##  data: NULL
  CLAP_CONTEXT_MENU_ITEM_END_SUBMENU* = 4 ##  Adds a title entry
                                       ##  data: const clap_context_menu_item_title_t *
  CLAP_CONTEXT_MENU_ITEM_TITLE* = 5

type
  clap_context_menu_item_kind* = uint32
  clap_context_menu_entry* {.bycopy.} = object
    ##  text to be displayed
    label*: cstring
    ##  if false, then the menu entry is greyed out and not clickable
    is_enabled*: bool
    action_id*: clap_id

  clap_context_menu_check_entry* {.bycopy.} = object
    ##  text to be displayed
    label*: cstring
    ##  if false, then the menu entry is greyed out and not clickable
    is_enabled*: bool
    ##  if true, then the menu entry will be displayed as checked
    is_checked*: bool
    action_id*: clap_id

  clap_context_menu_item_title* {.bycopy.} = object
    ##  text to be displayed
    title*: cstring
    ##  if false, then the menu entry is greyed out
    is_enabled*: bool

  clap_context_menu_submenu* {.bycopy.} = object
    ##  text to be displayed
    label*: cstring
    ##  if false, then the menu entry is greyed out and won't show submenu
    is_enabled*: bool


##  Context menu builder.
##  This object isn't thread-safe and must be used on the same thread as it was provided.

type
  clap_context_menu_builder* {.bycopy.} = object
    ctx*: pointer
    ##  Adds an entry to the menu.
    ##  entry_data type is determined by entry_kind.
    add_item*: proc (builder: ptr clap_context_menu_builder;
                   item_kind: clap_context_menu_item_kind; item_data: pointer): bool {.
        cdecl.}
    ##  Returns true if the menu builder supports the given item kind
    supports*: proc (builder: ptr clap_context_menu_builder;
                   item_kind: clap_context_menu_item_kind): bool {.cdecl.}

  clap_plugin_context_menu* {.bycopy.} = object
    ##  Insert plugin's menu items into the menu builder.
    ##  If target is null, assume global context.
    ##  [main-thread]
    populate*: proc (plugin: ptr clap_plugin; target: ptr clap_context_menu_target;
                   builder: ptr clap_context_menu_builder): bool {.cdecl.}
    ##  Performs the given action, which was previously provided to the host via populate().
    ##  If target is null, assume global context.
    ##  [main-thread]
    perform*: proc (plugin: ptr clap_plugin; target: ptr clap_context_menu_target;
                  action_id: clap_id): bool {.cdecl.}

  clap_host_context_menu* {.bycopy.} = object
    ##  Insert host's menu items into the menu builder.
    ##  If target is null, assume global context.
    ##  [main-thread]
    populate*: proc (host: ptr clap_host; target: ptr clap_context_menu_target;
                   builder: ptr clap_context_menu_builder): bool {.cdecl.}
    ##  Performs the given action, which was previously provided to the plugin via populate().
    ##  If target is null, assume global context.
    ##  [main-thread]
    perform*: proc (host: ptr clap_host; target: ptr clap_context_menu_target;
                  action_id: clap_id): bool {.cdecl.}
    ##  Returns true if the host can display a popup menu for the plugin.
    ##  This may depend upon the current windowing system used to display the plugin, so the
    ##  return value is invalidated after creating the plugin window.
    ##  [main-thread]
    can_popup*: proc (host: ptr clap_host): bool {.cdecl.}
    ##  Shows the host popup menu for a given parameter.
    ##  If the plugin is using embedded GUI, then x and y are relative to the plugin's window,
    ##  otherwise they're absolute coordinate, and screen index might be set accordingly.
    ##  If target is null, assume global context.
    ##  [main-thread]
    popup*: proc (host: ptr clap_host; target: ptr clap_context_menu_target;
                screen_index: int32; x: int32; y: int32): bool {.cdecl.}

