import ../plugin, ../host

## @page GUI
##
## This extension defines how the plugin will present its GUI.
##
## There are two approaches:
## 1. the plugin creates a window and embeds it into the host's window
## 2. the plugin creates a floating window
##
## Embedding the window gives more control to the host, and feels more integrated.
## Floating window are sometimes the only option due to technical limitations.
##
## The Embedding protocol is by far the most common, supported by all hosts to date,
## and a plugin author should support at least that case.
##
## Showing the GUI works as follow:
##  1. `PluginGui.isApiSupported`, check what can work
##  2. `PluginGui.create`, allocates gui resources
##  3. if the plugin window is floating
##  4.    -> `PluginGui.setTransient`
##  5.    -> `PluginGui.suggestTitle`
##  6. else
##  7.    -> `PluginGui.setScale`
##  8.    -> `PluginGui.canResize`
##  9.    -> if resizable and has known size from previous session, `PluginGui.setSize`
## 10.    -> else `PluginGui.getSize`, gets initial size
## 11.    -> `PluginGui.setParent`
## 12. `PluginGui.show`
## 13. `PluginGui.hide`/`PluginGui.show` ...
## 14. `PluginGui.destroy` when done with the gui
##
## Resizing the window (initiated by the plugin, if embedded):
## 1. Plugins calls `HostGui.requestResize`
## 2. If the host returns true the new size is accepted,
##    the host doesn't have to call `PluginGui.setSize`.
##    If the host returns false, the new size is rejected.
##
## Resizing the window (drag, if embedded)):
## 1. Only possible if `PluginGui.canResize` returns true
## 2. Mouse drag -> `newSize`
## 3. `PluginGui.adjustSize(newSize)` -> `workingSize`
## 4. `PluginGui.setSize(workingSize)`

let extGui*: cstring = cstring"clap.gui"

## If your windowing API is not listed here, please open an issue and we'll figure
## it out.
## https://github.com/free-audio/clap/issues/new

let windowApiWin32*: cstring = cstring"win32"
  ## uses physical size
  ## embed using https://docs.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-setparent

let windowApiCocoa*: cstring = cstring"cocoa"
  ## uses logical size, don't call `PluginGui.setScale`

let windowApiUikit*: cstring = cstring"uikit"
  ## uses logical size, don't call `PluginGui.setScale`

let windowApiX11*: cstring = cstring"x11"
  ## uses physical size
  ## embed using https://specifications.freedesktop.org/xembed-spec/xembed-spec-latest.html

let windowApiWayland*: cstring = cstring"wayland"
  ## uses physical size
  ## embed is currently not supported, use floating windows

type
  Hwnd* = pointer
  Nsview* = pointer
  Uiview* = pointer
  Xwnd* = culong

type
  INNER_C_UNION_gui_prepared_2* {.bycopy, union.} = object
    cocoa*: Nsview
    uikit*: Uiview
    x11*: Xwnd
    win32*: Hwnd
    `ptr`*: pointer
      ## for anything defined outside of clap

  Window* {.bycopy.} = object
    ## Represent a window reference.
    api*: cstring
      ## one of the `windowApi*` constants
    anoGuiPrepared3*: INNER_C_UNION_gui_prepared_2

type GuiResizeHints* {.bycopy.} = object
  ## Information to improve window resizing when initiated by the host or window
  ## manager.
  canResizeHorizontally*: bool
  canResizeVertically*: bool
  preserveAspectRatio*: bool
    ## if both horizontal and vertical resize are available, do we preserve the
    ## aspect ratio, and if so, what is the width x height aspect ratio to preserve.
    ## These flags are unused if `canResizeHorizontally` or vertically are false,
    ## and ratios are unused if preserve is false.
  aspectRatioWidth*: uint32
  aspectRatioHeight*: uint32

type
  PluginGui* {.bycopy.} = object
    ## Size (width, height) is in pixels; the corresponding windowing system
    ## extension is responsible for defining if it is physical pixels or logical
    ## pixels.
    isApiSupported*:
      proc(plugin: ptr Plugin, api: cstring, isFloating: bool): bool {.cdecl.}
      ## Returns true if the requested gui api is supported, either in floating
      ## (plugin-created) or non-floating (embedded) mode.
      ## `[main-thread]`
    getPreferredApi*:
      proc(plugin: ptr Plugin, api: cstringArray, isFloating: ptr bool): bool {.cdecl.}
      ## Returns true if the plugin has a preferred api.
      ## The host has no obligation to honor the plugin preference, this is just a
      ## hint.
      ## The `api` variable should be explicitly assigned as a pointer to one of the
      ## `windowApi*` constants defined above, not strcopied.
      ## `[main-thread]`
    create*: proc(plugin: ptr Plugin, api: cstring, isFloating: bool): bool {.cdecl.}
      ## Create and allocate all resources necessary for the gui.
      ##
      ## If `isFloating` is true, then the window will not be managed by the host.
      ## The plugin can set its window to stays above the parent window, see
      ## `setTransient`.
      ## api may be null or blank for floating window.
      ##
      ## If `isFloating` is false, then the plugin has to embed its window into the
      ## parent window, see `setParent`.
      ##
      ## After this call, the GUI may not be visible yet; don't forget to call
      ## `show`.
      ##
      ## Returns true if the GUI is successfully created.
      ## `[main-thread]`
    destroy*: proc(plugin: ptr Plugin) {.cdecl.}
      ## Free all resources associated with the gui.
      ## `[main-thread]`
    setScale*: proc(plugin: ptr Plugin, scale: cdouble): bool {.cdecl.}
      ## Set the absolute GUI scaling factor, and override any OS info.
      ## Should not be used if the windowing api relies upon logical pixels.
      ##
      ## If the plugin prefers to work out the scaling factor itself by querying the
      ## OS directly, then ignore the call.
      ##
      ## scale = 2 means 200% scaling.
      ##
      ## Returns true if the scaling could be applied.
      ## Returns false if the call was ignored, or the scaling could not be applied.
      ## `[main-thread]`
    getSize*:
      proc(plugin: ptr Plugin, width: ptr uint32, height: ptr uint32): bool {.cdecl.}
      ## Get the current size of the plugin UI.
      ## `create` must have been called prior to asking the size.
      ##
      ## Returns true if the plugin could get the size.
      ## `[main-thread]`
    canResize*: proc(plugin: ptr Plugin): bool {.cdecl.}
      ## Returns true if the window is resizeable (mouse drag).
      ## `[main-thread & !floating]`
    getResizeHints*: proc(plugin: ptr Plugin, hints: ptr GuiResizeHints): bool {.cdecl.}
      ## Returns true if the plugin can provide hints on how to resize the window.
      ## `[main-thread & !floating]`
    adjustSize*:
      proc(plugin: ptr Plugin, width: ptr uint32, height: ptr uint32): bool {.cdecl.}
      ## If the plugin gui is resizable, then the plugin will calculate the closest
      ## usable size which fits in the given size.
      ## This method does not change the size.
      ##
      ## Returns true if the plugin could adjust the given size.
      ## `[main-thread & !floating]`
    setSize*: proc(plugin: ptr Plugin, width: uint32, height: uint32): bool {.cdecl.}
      ## Sets the window size.
      ##
      ## Returns true if the plugin could resize its window to the given size.
      ## `[main-thread & !floating]`
    setParent*: proc(plugin: ptr Plugin, window: ptr Window): bool {.cdecl.}
      ## Embeds the plugin window into the given window.
      ##
      ## Returns true on success.
      ## `[main-thread & !floating]`
    setTransient*: proc(plugin: ptr Plugin, window: ptr Window): bool {.cdecl.}
      ## Set the plugin floating window to stay above the given window.
      ##
      ## Returns true on success.
      ## `[main-thread & floating]`
    suggestTitle*: proc(plugin: ptr Plugin, title: cstring) {.cdecl.}
      ## Suggests a window title. Only for floating windows.
      ##
      ## `[main-thread & floating]`
    show*: proc(plugin: ptr Plugin): bool {.cdecl.}
      ## Show the window.
      ##
      ## Returns true on success.
      ## `[main-thread]`
    hide*: proc(plugin: ptr Plugin): bool {.cdecl.}
      ## Hide the window, this method does not free the resources, it just hides the
      ## window content. Yet it may be a good idea to stop painting timers.
      ##
      ## Returns true on success.
      ## `[main-thread]`

  HostGui* {.bycopy.} = object
    resizeHintsChanged*: proc(host: ptr Host) {.cdecl.}
      ## The host should call `PluginGui.getResizeHints` again.
      ## `[thread-safe & !floating]`
    requestResize*: proc(host: ptr Host, width: uint32, height: uint32): bool {.cdecl.}
      ## Request the host to resize the client area to width, height.
      ## Return true if the new size is accepted, false otherwise.
      ## The host doesn't have to call `PluginGui.setSize`.
      ##
      ## Note: if not called from the main thread, then a return value simply means
      ## that the host acknowledged the request and will process it asynchronously.
      ## If the request then can't be satisfied then the host will call
      ## `PluginGui.setSize` to revert the operation.
      ## `[thread-safe & !floating]`
    requestShow*: proc(host: ptr Host): bool {.cdecl.}
      ## Request the host to show the plugin gui.
      ## Return true on success, false otherwise.
      ## `[thread-safe]`
    requestHide*: proc(host: ptr Host): bool {.cdecl.}
      ## Request the host to hide the plugin gui.
      ## Return true on success, false otherwise.
      ## `[thread-safe]`
    closed*: proc(host: ptr Host, wasDestroyed: bool) {.cdecl.}
      ## The floating window has been closed, or the connection to the gui has been
      ## lost.
      ##
      ## If `wasDestroyed` is true, then the host must call `PluginGui.destroy` to
      ## acknowledge the gui destruction.
      ## `[thread-safe]`
