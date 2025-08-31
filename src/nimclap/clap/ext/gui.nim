import ../plugin

##  @page GUI
##
##  This extension defines how the plugin will present its GUI.
##
##  There are two approaches:
##  1. the plugin creates a window and embeds it into the host's window
##  2. the plugin creates a floating window
##
##  Embedding the window gives more control to the host, and feels more integrated.
##  Floating window are sometimes the only option due to technical limitations.
##
##  The Embedding protocol is by far the most common, supported by all hosts to date,
##  and a plugin author should support at least that case.
##
##  Showing the GUI works as follow:
##   1. clap_plugin_gui->is_api_supported(), check what can work
##   2. clap_plugin_gui->create(), allocates gui resources
##   3. if the plugin window is floating
##   4.    -> clap_plugin_gui->set_transient()
##   5.    -> clap_plugin_gui->suggest_title()
##   6. else
##   7.    -> clap_plugin_gui->set_scale()
##   8.    -> clap_plugin_gui->can_resize()
##   9.    -> if resizable and has known size from previous session, clap_plugin_gui->set_size()
##  10.    -> else clap_plugin_gui->get_size(), gets initial size
##  11.    -> clap_plugin_gui->set_parent()
##  12. clap_plugin_gui->show()
##  13. clap_plugin_gui->hide()/show() ...
##  14. clap_plugin_gui->destroy() when done with the gui
##
##  Resizing the window (initiated by the plugin, if embedded):
##  1. Plugins calls clap_host_gui->request_resize()
##  2. If the host returns true the new size is accepted,
##     the host doesn't have to call clap_plugin_gui->set_size().
##     If the host returns false, the new size is rejected.
##
##  Resizing the window (drag, if embedded)):
##  1. Only possible if clap_plugin_gui->can_resize() returns true
##  2. Mouse drag -> new_size
##  3. clap_plugin_gui->adjust_size(new_size) -> working_size
##  4. clap_plugin_gui->set_size(working_size)

let extGui*: cstring = cstring"clap.gui"

##  If your windowing API is not listed here, please open an issue and we'll figure it out.
##  https://github.com/free-audio/clap/issues/new
##  uses physical size
##  embed using https://docs.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-setparent

let windowApiWin32*: cstring = cstring"win32"

##  uses logical size, don't call clap_plugin_gui->set_scale()

let windowApiCocoa*: cstring = cstring"cocoa"

##  uses physical size
##  embed using https://specifications.freedesktop.org/xembed-spec/xembed-spec-latest.html

let windowApiX11*: cstring = cstring"x11"

##  uses physical size
##  embed is currently not supported, use floating windows

let windowApiWayland*: cstring = cstring"wayland"

type
  Hwnd* = pointer
  Nsview* = pointer
  Xwnd* = culong

##  Represent a window reference.

type
  INNER_C_UNION_gui_prepared_2* {.bycopy, union.} = object
    cocoa*: Nsview
    x11*: Xwnd
    win32*: Hwnd
    `ptr`*: pointer ##  for anything defined outside of clap

  Window* {.bycopy.} = object
    api*: cstring
    ##  one of CLAP_WINDOW_API_XXX
    anoGuiPrepared3*: INNER_C_UNION_gui_prepared_2

##  Information to improve window resizing when initiated by the host or window manager.

type GuiResizeHints* {.bycopy.} = object
  canResizeHorizontally*: bool
  canResizeVertically*: bool
  ##  if both horizontal and vertical resize are available, do we preserve the
  ##  aspect ratio, and if so, what is the width x height aspect ratio to preserve.
  ##  These flags are unused if can_resize_horizontally or vertically are false,
  ##  and ratios are unused if preserve is false.
  preserveAspectRatio*: bool
  aspectRatioWidth*: uint32
  aspectRatioHeight*: uint32

##  Size (width, height) is in pixels; the corresponding windowing system extension is
##  responsible for defining if it is physical pixels or logical pixels.

type
  PluginGui* {.bycopy.} = object
    ##  Returns true if the requested gui api is supported, either in floating (plugin-created)
    ##  or non-floating (embedded) mode.
    ##  [main-thread]
    isApiSupported*:
      proc(plugin: ptr Plugin, api: cstring, isFloating: bool): bool {.cdecl.}
    ##  Returns true if the plugin has a preferred api.
    ##  The host has no obligation to honor the plugin preference, this is just a hint.
    ##  The const char **api variable should be explicitly assigned as a pointer to
    ##  one of the CLAP_WINDOW_API_ constants defined above, not strcopied.
    ##  [main-thread]
    getPreferredApi*:
      proc(plugin: ptr Plugin, api: cstringArray, isFloating: ptr bool): bool {.cdecl.}
    ##  Create and allocate all resources necessary for the gui.
    ##
    ##  If is_floating is true, then the window will not be managed by the host. The plugin
    ##  can set its window to stays above the parent window, see set_transient().
    ##  api may be null or blank for floating window.
    ##
    ##  If is_floating is false, then the plugin has to embed its window into the parent window, see
    ##  set_parent().
    ##
    ##  After this call, the GUI may not be visible yet; don't forget to call show().
    ##
    ##  Returns true if the GUI is successfully created.
    ##  [main-thread]
    create*: proc(plugin: ptr Plugin, api: cstring, isFloating: bool): bool {.cdecl.}
    ##  Free all resources associated with the gui.
    ##  [main-thread]
    destroy*: proc(plugin: ptr Plugin) {.cdecl.}
    ##  Set the absolute GUI scaling factor, and override any OS info.
    ##  Should not be used if the windowing api relies upon logical pixels.
    ##
    ##  If the plugin prefers to work out the scaling factor itself by querying the OS directly,
    ##  then ignore the call.
    ##
    ##  scale = 2 means 200% scaling.
    ##
    ##  Returns true if the scaling could be applied
    ##  Returns false if the call was ignored, or the scaling could not be applied.
    ##  [main-thread]
    setScale*: proc(plugin: ptr Plugin, scale: cdouble): bool {.cdecl.}
    ##  Get the current size of the plugin UI.
    ##  clap_plugin_gui->create() must have been called prior to asking the size.
    ##
    ##  Returns true if the plugin could get the size.
    ##  [main-thread]
    getSize*:
      proc(plugin: ptr Plugin, width: ptr uint32, height: ptr uint32): bool {.cdecl.}
    ##  Returns true if the window is resizeable (mouse drag).
    ##  [main-thread & !floating]
    canResize*: proc(plugin: ptr Plugin): bool {.cdecl.}
    ##  Returns true if the plugin can provide hints on how to resize the window.
    ##  [main-thread & !floating]
    getResizeHints*: proc(plugin: ptr Plugin, hints: ptr GuiResizeHints): bool {.cdecl.}
    ##  If the plugin gui is resizable, then the plugin will calculate the closest
    ##  usable size which fits in the given size.
    ##  This method does not change the size.
    ##
    ##  Returns true if the plugin could adjust the given size.
    ##  [main-thread & !floating]
    adjustSize*:
      proc(plugin: ptr Plugin, width: ptr uint32, height: ptr uint32): bool {.cdecl.}
    ##  Sets the window size.
    ##
    ##  Returns true if the plugin could resize its window to the given size.
    ##  [main-thread & !floating]
    setSize*: proc(plugin: ptr Plugin, width: uint32, height: uint32): bool {.cdecl.}
    ##  Embeds the plugin window into the given window.
    ##
    ##  Returns true on success.
    ##  [main-thread & !floating]
    setParent*: proc(plugin: ptr Plugin, window: ptr Window): bool {.cdecl.}
    ##  Set the plugin floating window to stay above the given window.
    ##
    ##  Returns true on success.
    ##  [main-thread & floating]
    setTransient*: proc(plugin: ptr Plugin, window: ptr Window): bool {.cdecl.}
    ##  Suggests a window title. Only for floating windows.
    ##
    ##  [main-thread & floating]
    suggestTitle*: proc(plugin: ptr Plugin, title: cstring) {.cdecl.}
    ##  Show the window.
    ##
    ##  Returns true on success.
    ##  [main-thread]
    show*: proc(plugin: ptr Plugin): bool {.cdecl.}
    ##  Hide the window, this method does not free the resources, it just hides
    ##  the window content. Yet it may be a good idea to stop painting timers.
    ##
    ##  Returns true on success.
    ##  [main-thread]
    hide*: proc(plugin: ptr Plugin): bool {.cdecl.}

  HostGui* {.bycopy.} = object
    ##  The host should call get_resize_hints() again.
    ##  [thread-safe & !floating]
    resizeHintsChanged*: proc(host: ptr Host) {.cdecl.}
    ##  Request the host to resize the client area to width, height.
    ##  Return true if the new size is accepted, false otherwise.
    ##  The host doesn't have to call set_size().
    ##
    ##  Note: if not called from the main thread, then a return value simply means that the host
    ##  acknowledged the request and will process it asynchronously. If the request then can't be
    ##  satisfied then the host will call set_size() to revert the operation.
    ##  [thread-safe & !floating]
    requestResize*: proc(host: ptr Host, width: uint32, height: uint32): bool {.cdecl.}
    ##  Request the host to show the plugin gui.
    ##  Return true on success, false otherwise.
    ##  [thread-safe]
    requestShow*: proc(host: ptr Host): bool {.cdecl.}
    ##  Request the host to hide the plugin gui.
    ##  Return true on success, false otherwise.
    ##  [thread-safe]
    requestHide*: proc(host: ptr Host): bool {.cdecl.}
    ##  The floating window has been closed, or the connection to the gui has been lost.
    ##
    ##  If was_destroyed is true, then the host must call clap_plugin_gui->destroy() to acknowledge
    ##  the gui destruction.
    ##  [thread-safe]
    closed*: proc(host: ptr Host, wasDestroyed: bool) {.cdecl.}
