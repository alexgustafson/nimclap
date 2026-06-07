import ../plugin, ../host, ../id

## This extension lets the host and plugin exchange menu items and let the plugin
## ask the host to show its context menu.

let extContextMenu*: cstring = cstring"clap.context-menu/1"

let extContextMenuCompat*: cstring = cstring"clap.context-menu.draft/0"
  ## The latest draft is 100% compatible.
  ## This compat ID may be removed in 2026.

const
  contextMenuTargetKindGlobal* = 0
    ## There can be different target kind for a context menu.
  contextMenuTargetKindParam* = 1

type ContextMenuTarget* {.bycopy.} = object
  ## Describes the context menu target.
  kind*: uint32
  id*: Id

const
  contextMenuItemEntry* = 0
    ## Adds a clickable menu entry.
    ## data: `ContextMenuItemEntry`
  contextMenuItemCheckEntry* = 1
    ## Adds a clickable menu entry which will feature both a checkmark and a label.
    ## data: `ContextMenuItemCheckEntry`
  contextMenuItemSeparator* = 2
    ## Adds a separator line.
    ## data: `nil`
  contextMenuItemBeginSubmenu* = 3
    ## Starts a sub menu with the given label.
    ## data: `ContextMenuItemBeginSubmenu`
  contextMenuItemEndSubmenu* = 4
    ## Ends the current sub menu.
    ## data: `nil`
  contextMenuItemTitle* = 5
    ## Adds a title entry.
    ## data: `ContextMenuItemTitle`

type
  ContextMenuItemKind* = uint32
  ContextMenuEntry* {.bycopy.} = object
    label*: cstring
      ## text to be displayed
    isEnabled*: bool
      ## if false, then the menu entry is greyed out and not clickable
    actionId*: Id

  ContextMenuCheckEntry* {.bycopy.} = object
    label*: cstring
      ## text to be displayed
    isEnabled*: bool
      ## if false, then the menu entry is greyed out and not clickable
    isChecked*: bool
      ## if true, then the menu entry will be displayed as checked
    actionId*: Id

  ContextMenuItemTitle* {.bycopy.} = object
    title*: cstring
      ## text to be displayed
    isEnabled*: bool
      ## if false, then the menu entry is greyed out

  ContextMenuSubmenu* {.bycopy.} = object
    label*: cstring
      ## text to be displayed
    isEnabled*: bool
      ## if false, then the menu entry is greyed out and won't show submenu

type
  ContextMenuBuilder* {.bycopy.} = object
    ## Context menu builder.
    ## This object isn't thread-safe and must be used on the same thread as it was
    ## provided.
    ctx*: pointer
    addItem*: proc(
      builder: ptr ContextMenuBuilder, itemKind: ContextMenuItemKind, itemData: pointer
    ): bool {.cdecl.}
      ## Adds an entry to the menu.
      ## `itemData` type is determined by `itemKind`.
      ## Returns true on success.
    supports*: proc(
      builder: ptr ContextMenuBuilder, itemKind: ContextMenuItemKind
    ): bool {.cdecl.}
      ## Returns true if the menu builder supports the given item kind.

  PluginContextMenu* {.bycopy.} = object
    populate*: proc(
      plugin: ptr Plugin, target: ptr ContextMenuTarget, builder: ptr ContextMenuBuilder
    ): bool {.cdecl.}
      ## Insert plugin's menu items into the menu builder.
      ## If target is null, assume global context.
      ## Returns true on success.
      ## `[main-thread]`
    perform*: proc(
      plugin: ptr Plugin, target: ptr ContextMenuTarget, actionId: Id
    ): bool {.cdecl.}
      ## Performs the given action, which was previously provided to the host via
      ## `populate`.
      ## If target is null, assume global context.
      ## Returns true on success.
      ## `[main-thread]`

  HostContextMenu* {.bycopy.} = object
    populate*: proc(
      host: ptr Host, target: ptr ContextMenuTarget, builder: ptr ContextMenuBuilder
    ): bool {.cdecl.}
      ## Insert host's menu items into the menu builder.
      ## If target is null, assume global context.
      ## Returns true on success.
      ## `[main-thread]`
    perform*:
      proc(host: ptr Host, target: ptr ContextMenuTarget, actionId: Id): bool {.cdecl.}
      ## Performs the given action, which was previously provided to the plugin via
      ## `populate`.
      ## If target is null, assume global context.
      ## Returns true on success.
      ## `[main-thread]`
    canPopup*: proc(host: ptr Host): bool {.cdecl.}
      ## Returns true if the host can display a popup menu for the plugin.
      ## This may depend upon the current windowing system used to display the
      ## plugin, so the return value is invalidated after creating the plugin window.
      ## `[main-thread]`
    popup*: proc(
      host: ptr Host,
      target: ptr ContextMenuTarget,
      screenIndex: int32,
      x: int32,
      y: int32,
    ): bool {.cdecl.}
      ## Shows the host popup menu for a given parameter.
      ## If the plugin is using embedded GUI, then x and y are relative to the
      ## plugin's window, otherwise they're absolute coordinate, and screen index
      ## might be set accordingly.
      ## If target is null, assume global context.
      ## Returns true on success.
      ## `[main-thread]`
