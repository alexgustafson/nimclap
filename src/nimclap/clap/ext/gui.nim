import
  ../plugin

## / @page GUI
## /
## / This extension defines how the plugin will present its GUI.
## /
## / There are two approaches:
## / 1. the plugin creates a window and embeds it into the host's window
## / 2. the plugin creates a floating window
## /
## / Embedding the window gives more control to the host, and feels more integrated.
## / Floating window are sometimes the only option due to technical limitations.
## /
## / Showing the GUI works as follow:
## /  1. clap_plugin_gui->is_api_supported(), check what can work
## /  2. clap_plugin_gui->create(), allocates gui resources
## /  3. if the plugin window is floating
## /  4.    -> clap_plugin_gui->set_transient()
## /  5.    -> clap_plugin_gui->suggest_title()
## /  6. else
## /  7.    -> clap_plugin_gui->set_scale()
## /  8.    -> clap_plugin_gui->can_resize()
## /  9.    -> if resizable and has known size from previous session, clap_plugin_gui->set_size()
## / 10.    -> else clap_plugin_gui->get_size(), gets initial size
## / 11.    -> clap_plugin_gui->set_parent()
## / 12. clap_plugin_gui->show()
## / 13. clap_plugin_gui->hide()/show() ...
## / 14. clap_plugin_gui->destroy() when done with the gui
## /
## / Resizing the window (initiated by the plugin, if embedded):
## / 1. Plugins calls clap_host_gui->request_resize()
## / 2. If the host returns true the new size is accepted,
## /    the host doesn't have to call clap_plugin_gui->set_size().
## /    If the host returns false, the new size is rejected.
## /
## / Resizing the window (drag, if embedded)):
## / 1. Only possible if clap_plugin_gui->can_resize() returns true
## / 2. Mouse drag -> new_size
## / 3. clap_plugin_gui->adjust_size(new_size) -> working_size
## / 4. clap_plugin_gui->set_size(working_size)

var CLAP_EXT_GUI*: UncheckedArray[char] = "clap.gui"

##  If your windowing API is not listed here, please open an issue and we'll figure it out.
##  https://github.com/free-audio/clap/issues/new
##  uses physical size
##  embed using https://docs.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-setparent

var CLAP_WINDOW_API_WIN32*: UncheckedArray[char] = "win32"

##  uses logical size, don't call clap_plugin_gui->set_scale()

var CLAP_WINDOW_API_COCOA*: UncheckedArray[char] = "cocoa"

##  uses physical size
##  embed using https://specifications.freedesktop.org/xembed-spec/xembed-spec-latest.html

var CLAP_WINDOW_API_X11*: UncheckedArray[char] = "x11"

##  uses physical size
##  embed is currently not supported, use floating windows

var CLAP_WINDOW_API_WAYLAND*: UncheckedArray[char] = "wayland"

type
  ClapHwnd* = pointer
  ClapNsview* = pointer
  ClapXwnd* = culong

##  Represent a window reference.

type
  INNER_C_UNION_gui_modified_86* {.bycopy, union.} = object
    cocoa*: ClapNsview
    x11*: ClapXwnd
    win32*: ClapHwnd
    `ptr`*: pointer            ##  for anything defined outside of clap

  ClapWindowT* {.bycopy.} = object
    api*: cstring              ##  one of CLAP_WINDOW_API_XXX
    anoGuiModified86*: INNER_C_UNION_gui_modified_86


##  Information to improve window resizement when initiated by the host or window manager.

type
  ClapGuiResizeHintsT* {.bycopy.} = object
    canResizeHorizontally*: bool
    canResizeVertically*: bool ##  only if can resize horizontally and vertically
    preseveAspectRatio*: bool
    aspectRatioWidth*: uint32T
    aspectRatioHeight*: uint32T


##  Size (width, height) is in pixels; the corresponding windowing system extension is
##  responsible to define if it is physical pixels or logical pixels.

type
  ClapPluginGuiT* {.bycopy.} = object
    isApiSupported*: proc (plugin: ptr ClapPluginT; api: cstring; isFloating: bool): bool ##  Returns true if the requested gui api is supported
                                                                                ##  [main-thread]
    ##  Returns true if the plugin has a preferred api.
    ##  The host has no obligation to honor the plugin preferrence, this is just a hint.
    ##  [main-thread]
    getPreferredApi*: proc (plugin: ptr ClapPluginT; api: cstringArray;
                          isFloating: ptr bool): bool ##  Create and allocate all resources necessary for the gui.
                                                  ##
                                                  ##  If is_floating is true, then the window will not be managed by the host. The plugin
                                                  ##  can set its window to stays above the parent window, see set_transient().
                                                  ##  api may be null or blank for floating window.
                                                  ##
                                                  ##  If is_floating is false, then the plugin has to embbed its window into the parent window, see
                                                  ##  set_parent().
                                                  ##
                                                  ##  After this call, the GUI may not be visible yet; don't forget to call show().
                                                  ##  [main-thread]
    create*: proc (plugin: ptr ClapPluginT; api: cstring; isFloating: bool): bool ##  Free all resources associated with the gui.
                                                                        ##  [main-thread]
    destroy*: proc (plugin: ptr ClapPluginT) ##  Set the absolute GUI scaling factor, and override any OS info.
                                        ##  Should not be used if the windowing api relies upon logical pixels.
                                        ##
                                        ##  If the plugin prefers to work out the scaling factor itself by querying the OS directly,
                                        ##  then ignore the call.
                                        ##
                                        ##  Returns true if the scaling could be applied
                                        ##  Returns false if the call was ignored, or the scaling could not be applied.
                                        ##  [main-thread]
    setScale*: proc (plugin: ptr ClapPluginT; scale: cdouble): bool ##  Get the current size of the plugin UI.
                                                            ##  clap_plugin_gui->create() must have been called prior to asking the size.
                                                            ##  [main-thread]
    getSize*: proc (plugin: ptr ClapPluginT; width: ptr uint32T; height: ptr uint32T): bool ##  Returns true if the window is resizeable (mouse drag).
                                                                                ##  Only for embedded windows.
                                                                                ##  [main-thread]
    canResize*: proc (plugin: ptr ClapPluginT): bool ##  Returns true if the plugin can provide hints on how to resize the window.
                                               ##  [main-thread]
    getResizeHints*: proc (plugin: ptr ClapPluginT; hints: ptr ClapGuiResizeHintsT): bool ##  If the plugin gui is resizable, then the plugin will calculate the closest
                                                                                 ##  usable size which fits in the given size.
                                                                                 ##  This method does not change the size.
                                                                                 ##
                                                                                 ##  Only for embedded windows.
                                                                                 ##  [main-thread]
    adjustSize*: proc (plugin: ptr ClapPluginT; width: ptr uint32T; height: ptr uint32T): bool ##  Sets the window size. Only for embedded windows.
                                                                                   ##  [main-thread]
    setSize*: proc (plugin: ptr ClapPluginT; width: uint32T; height: uint32T): bool ##  Embbeds the plugin window into the given window.
                                                                          ##  [main-thread & !floating]
    setParent*: proc (plugin: ptr ClapPluginT; window: ptr ClapWindowT): bool ##  Set the plugin floating window to stay above the given window.
                                                                     ##  [main-thread & floating]
    setTransient*: proc (plugin: ptr ClapPluginT; window: ptr ClapWindowT): bool ##  Suggests a window title. Only for floating windows.
                                                                        ##  [main-thread & floating]
    suggestTitle*: proc (plugin: ptr ClapPluginT; title: cstring) ##  Show the window.
                                                           ##  [main-thread]
    show*: proc (plugin: ptr ClapPluginT): bool ##  Hide the window, this method do not free the resources, it just hides
                                          ##  the window content. Yet it maybe a good idea to stop painting timers.
                                          ##  [main-thread]
    hide*: proc (plugin: ptr ClapPluginT): bool

  ClapHostGuiT* {.bycopy.} = object
    resizeHintsChanged*: proc (host: ptr ClapHostT) ##  The host should call get_resize_hints() again.
                                               ##  [thread-safe]
    ##  Request the host to resize the client area to width, height.
    ##  Return true if the new size is accepted, false otherwise.
    ##  The host doesn't have to call set_size().
    ##
    ##  Note: if not called from the main thread, then a return value simply means that the host
    ##  acknowledge the request and will process it asynchronously. If the request then can't be
    ##  satisfied then the host will call set_size() to revert the operation.
    ##
    ##  [thread-safe]
    requestResize*: proc (host: ptr ClapHostT; width: uint32T; height: uint32T): bool ##  Request the host to show the plugin gui.
                                                                            ##  Return true on success, false otherwise.
                                                                            ##  [thread-safe]
    requestShow*: proc (host: ptr ClapHostT): bool ##  Request the host to hide the plugin gui.
                                             ##  Return true on success, false otherwise.
                                             ##  [thread-safe]
    requestHide*: proc (host: ptr ClapHostT): bool ##  The floating window has been closed, or the connection to the gui has been lost.
                                             ##
                                             ##  If was_destroyed is true, then the host must call clap_plugin_gui->destroy() to acknowledge
                                             ##  the gui destruction.
                                             ##  [thread-safe]
    closed*: proc (host: ptr ClapHostT; wasDestroyed: bool)

