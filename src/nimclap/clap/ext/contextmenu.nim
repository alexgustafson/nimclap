import ../plugin

##  This extension lets the host and plugin exchange menu items and let the plugin ask the host to
##  show its context menu.

let extContextMenu*: cstring = cstring"clap.context-menu/1"

##  The latest draft is 100% compatible.
##  This compat ID may be removed in 2026.

let extContextMenuCompat*: cstring = cstring"clap.context-menu.draft/0"

##  There can be different target kind for a context menu

const
  contextMenuTargetKindGlobal* = 0
  contextMenuTargetKindParam* = 1

##  Describes the context menu target

type ContextMenuTarget* {.bycopy.} = object
  kind*: uint32
  id*: Id

const
  ##  Adds a clickable menu entry.
  ##  data: const clap_context_menu_item_entry_t*
  contextMenuItemEntry* = 0
    ##  Adds a clickable menu entry which will feature both a checkmark and a label.
    ##  data: const clap_context_menu_item_check_entry_t*
  contextMenuItemCheckEntry* = 1
    ##  Adds a separator line.
    ##  data: NULL
  contextMenuItemSeparator* = 2
    ##  Starts a sub menu with the given label.
    ##  data: const clap_context_menu_item_begin_submenu_t*
  contextMenuItemBeginSubmenu* = 3
    ##  Ends the current sub menu.
    ##  data: NULL
  contextMenuItemEndSubmenu* = 4
    ##  Adds a title entry
    ##  data: const clap_context_menu_item_title_t *
  contextMenuItemTitle* = 5

type
  ContextMenuItemKind* = uint32
  ContextMenuEntry* {.bycopy.} = object ##  text to be displayed
    label*: cstring
    ##  if false, then the menu entry is greyed out and not clickable
    isEnabled*: bool
    actionId*: Id

  ContextMenuCheckEntry* {.bycopy.} = object ##  text to be displayed
    label*: cstring
    ##  if false, then the menu entry is greyed out and not clickable
    isEnabled*: bool
    ##  if true, then the menu entry will be displayed as checked
    isChecked*: bool
    actionId*: Id

  ContextMenuItemTitle* {.bycopy.} = object ##  text to be displayed
    title*: cstring
    ##  if false, then the menu entry is greyed out
    isEnabled*: bool

  ContextMenuSubmenu* {.bycopy.} = object ##  text to be displayed
    label*: cstring
    ##  if false, then the menu entry is greyed out and won't show submenu
    isEnabled*: bool

##  Context menu builder.
##  This object isn't thread-safe and must be used on the same thread as it was provided.

type
  ContextMenuBuilder* {.bycopy.} = object
    ctx*: pointer
    ##  Adds an entry to the menu.
    ##  item_data type is determined by item_kind.
    ##  Returns true on success.
    addItem*: proc(
      builder: ptr ContextMenuBuilder, itemKind: ContextMenuItemKind, itemData: pointer
    ): bool {.cdecl.}
    ##  Returns true if the menu builder supports the given item kind
    supports*: proc(
      builder: ptr ContextMenuBuilder, itemKind: ContextMenuItemKind
    ): bool {.cdecl.}

  PluginContextMenu* {.bycopy.} = object
    ##  Insert plugin's menu items into the menu builder.
    ##  If target is null, assume global context.
    ##  Returns true on success.
    ##  [main-thread]
    populate*: proc(
      plugin: ptr Plugin, target: ptr ContextMenuTarget, builder: ptr ContextMenuBuilder
    ): bool {.cdecl.}
    ##  Performs the given action, which was previously provided to the host via populate().
    ##  If target is null, assume global context.
    ##  Returns true on success.
    ##  [main-thread]
    perform*: proc(
      plugin: ptr Plugin, target: ptr ContextMenuTarget, actionId: Id
    ): bool {.cdecl.}

  HostContextMenu* {.bycopy.} = object
    ##  Insert host's menu items into the menu builder.
    ##  If target is null, assume global context.
    ##  Returns true on success.
    ##  [main-thread]
    populate*: proc(
      host: ptr Host, target: ptr ContextMenuTarget, builder: ptr ContextMenuBuilder
    ): bool {.cdecl.}
    ##  Performs the given action, which was previously provided to the plugin via populate().
    ##  If target is null, assume global context.
    ##  Returns true on success.
    ##  [main-thread]
    perform*:
      proc(host: ptr Host, target: ptr ContextMenuTarget, actionId: Id): bool {.cdecl.}
    ##  Returns true if the host can display a popup menu for the plugin.
    ##  This may depend upon the current windowing system used to display the plugin, so the
    ##  return value is invalidated after creating the plugin window.
    ##  [main-thread]
    canPopup*: proc(host: ptr Host): bool {.cdecl.}
    ##  Shows the host popup menu for a given parameter.
    ##  If the plugin is using embedded GUI, then x and y are relative to the plugin's window,
    ##  otherwise they're absolute coordinate, and screen index might be set accordingly.
    ##  If target is null, assume global context.
    ##  Returns true on success.
    ##  [main-thread]
    popup*: proc(
      host: ptr Host,
      target: ptr ContextMenuTarget,
      screenIndex: int32,
      x: int32,
      y: int32,
    ): bool {.cdecl.}
